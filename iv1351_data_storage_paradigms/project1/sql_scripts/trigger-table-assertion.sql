CREATE OR REPLACE FUNCTION derived_planned_hours(given_course_instance_id INT, given_teaching_activity_id INT)
RETURNS INT AS $$
DECLARE
    hours INT;
BEGIN
    SELECT ROUND(
        derived_activity_formula.base_hours
        + derived_activity_formula.hours_per_student * course_instance.num_students
        + derived_activity_formula.hours_per_hp * course_layout.hp
    )
    INTO hours
    FROM derived_activity_formula
    INNER JOIN course_instance ON course_instance.id = given_course_instance_id
    INNER JOIN course_layout ON course_layout.id = course_instance.course_layout_id
    WHERE derived_activity_formula.teaching_activity_id = given_teaching_activity_id;

    IF hours IS NULL THEN
        RAISE EXCEPTION 'Problem: No derived formula for teaching activity id % or no course instance with id %', given_teaching_activity_id, given_course_instance_id;
    END IF;

    RETURN hours;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION insert_derived_planned_activity()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO planned_activity (planned_hours, teaching_activity_id, course_instance_id)
    SELECT
        derived_planned_hours(NEW.id, teaching_activity.id),
        teaching_activity.id,
        NEW.id
    FROM teaching_activity
    WHERE teaching_activity.activity_name IN ('Examination', 'Administration');

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trigger_insert_derived_planned_activity
AFTER INSERT
ON course_instance
FOR EACH ROW
EXECUTE FUNCTION insert_derived_planned_activity();

CREATE OR REPLACE FUNCTION recalculate_derived_planned_hours(given_course_instance_id INT)
RETURNS VOID AS $$
BEGIN
    UPDATE planned_activity
    SET planned_hours = derived_planned_hours(given_course_instance_id, planned_activity.teaching_activity_id)
    WHERE planned_activity.course_instance_id = given_course_instance_id
      AND planned_activity.teaching_activity_id IN (
          SELECT teaching_activity.id
          FROM teaching_activity
          WHERE teaching_activity.activity_name IN ('Examination', 'Administration')
      );
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION update_derived_planned_activity_num_students()
RETURNS TRIGGER AS $$
BEGIN
    PERFORM recalculate_derived_planned_hours(NEW.id);

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trigger_update_derived_planned_activity_num_students
AFTER UPDATE OF num_students
ON course_instance
FOR EACH ROW
WHEN (OLD.num_students IS DISTINCT FROM NEW.num_students)
EXECUTE FUNCTION update_derived_planned_activity_num_students();

CREATE OR REPLACE FUNCTION update_derived_planned_activity_hp()
RETURNS TRIGGER AS $$
BEGIN
    PERFORM recalculate_derived_planned_hours(course_instance.id)
    FROM course_instance
    WHERE course_instance.course_layout_id = NEW.id;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trigger_update_derived_planned_activity_hp
AFTER UPDATE OF hp
ON course_layout
FOR EACH ROW
WHEN (OLD.hp IS DISTINCT FROM NEW.hp)
EXECUTE FUNCTION update_derived_planned_activity_hp();

CREATE OR REPLACE FUNCTION protect_derived_planned_activity()
RETURNS TRIGGER AS $$
DECLARE
    given_teaching_activity_ids INT[];
BEGIN
    IF TG_OP = 'INSERT' THEN
        given_teaching_activity_ids := ARRAY[NEW.teaching_activity_id];
    ELSIF TG_OP = 'DELETE' THEN
        given_teaching_activity_ids := ARRAY[OLD.teaching_activity_id];
    ELSE
        given_teaching_activity_ids := ARRAY[OLD.teaching_activity_id, NEW.teaching_activity_id];
    END IF;

    IF pg_trigger_depth() = 1 AND EXISTS (
        SELECT 1
        FROM teaching_activity
        WHERE teaching_activity.id = ANY(given_teaching_activity_ids)
          AND teaching_activity.activity_name IN ('Administration', 'Examination')
    ) THEN
        RAISE EXCEPTION 'Problem: The planned activities Administration and Examination are created and calculated automatically and cannot be changed manually. Change course_instance.num_students or course_layout.hp instead';
    END IF;

    IF TG_OP = 'DELETE' THEN
        RETURN OLD;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trigger_protect_derived_planned_activity
BEFORE INSERT OR UPDATE OR DELETE
ON planned_activity
FOR EACH ROW
EXECUTE FUNCTION protect_derived_planned_activity();

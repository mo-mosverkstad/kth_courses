CREATE OR REPLACE FUNCTION max_instances_each_study_period()
RETURNS INT AS $$
DECLARE
    max_value INTEGER;
BEGIN
    SELECT policy_value
    INTO max_value
    FROM policy
    WHERE policy_name = 'allocation_rule';

    IF max_value IS NULL THEN
        RAISE EXCEPTION 'Problem: The policy allocation_rule is missing in table policy';
    END IF;

    RETURN max_value;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION validate_4_instances_each_study_period()
RETURNS TRIGGER AS $$
DECLARE
    new_instance_id INTEGER;
    new_academic_period_id INTEGER;
    current_value INTEGER;
    max_value INTEGER;
    old_planned_activity_id INTEGER;
BEGIN
    -- on update, the old row is still in the table and must not be counted,
    -- since it is the row that is being moved away
    IF TG_OP = 'UPDATE' THEN
        old_planned_activity_id := OLD.planned_activity_id;
    END IF;

    -- extract instance_id and academic_period_id
    SELECT course_instance.id, course_instance.academic_period_id
    INTO new_instance_id, new_academic_period_id
    FROM planned_activity
    INNER JOIN course_instance ON course_instance.id = planned_activity.course_instance_id
    WHERE planned_activity.id = NEW.planned_activity_id;

    -- count the number of teaching_allocation from given employee and academic period
    SELECT COUNT(DISTINCT course_instance.id)
    INTO current_value
    FROM teaching_allocation
    INNER JOIN planned_activity ON planned_activity.id = teaching_allocation.planned_activity_id
    INNER JOIN course_instance ON course_instance.id = planned_activity.course_instance_id
    WHERE teaching_allocation.employee_id = NEW.employee_id
      AND course_instance.academic_period_id = new_academic_period_id
      AND course_instance.id <> new_instance_id
      AND (old_planned_activity_id IS NULL
           OR teaching_allocation.planned_activity_id <> old_planned_activity_id
           OR teaching_allocation.employee_id <> OLD.employee_id);

    max_value := max_instances_each_study_period();

    IF current_value >= max_value THEN
        RAISE EXCEPTION 'Problem: A teacher cannot be assigned to more than % course instances each academic period. Employee id: %, already allocated: %', max_value, NEW.employee_id, current_value;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trigger_4_instances_each_study_period
BEFORE INSERT OR UPDATE OF planned_activity_id, employee_id
ON teaching_allocation
FOR EACH ROW
EXECUTE FUNCTION validate_4_instances_each_study_period();

-- The rule spans teaching_allocation, planned_activity and course_instance, so it can
-- also be broken from the two other tables, without inserting any allocation at all.
-- Those two cases are checked on the finished result instead, which is why the count
-- is compared with the maximum itself and not with the maximum minus one.

CREATE OR REPLACE FUNCTION validate_allocated_instances(given_employee_id INT, given_academic_period_id INT)
RETURNS VOID AS $$
DECLARE
    current_value INTEGER;
    max_value INTEGER;
BEGIN
    SELECT COUNT(DISTINCT course_instance.id)
    INTO current_value
    FROM teaching_allocation
    INNER JOIN planned_activity ON planned_activity.id = teaching_allocation.planned_activity_id
    INNER JOIN course_instance ON course_instance.id = planned_activity.course_instance_id
    WHERE teaching_allocation.employee_id = given_employee_id
      AND course_instance.academic_period_id = given_academic_period_id;

    max_value := max_instances_each_study_period();

    IF current_value > max_value THEN
        RAISE EXCEPTION 'Problem: A teacher cannot be assigned to more than % course instances each academic period. Employee id: %, allocated: %', max_value, given_employee_id, current_value;
    END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION validate_4_instances_planned_activity()
RETURNS TRIGGER AS $$
DECLARE
    new_academic_period_id INTEGER;
    given_employee_id INTEGER;
BEGIN
    SELECT course_instance.academic_period_id
    INTO new_academic_period_id
    FROM course_instance
    WHERE course_instance.id = NEW.course_instance_id;

    FOR given_employee_id IN
        SELECT teaching_allocation.employee_id
        FROM teaching_allocation
        WHERE teaching_allocation.planned_activity_id = NEW.id
    LOOP
        PERFORM validate_allocated_instances(given_employee_id, new_academic_period_id);
    END LOOP;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trigger_4_instances_planned_activity
AFTER UPDATE OF course_instance_id
ON planned_activity
FOR EACH ROW
WHEN (OLD.course_instance_id IS DISTINCT FROM NEW.course_instance_id)
EXECUTE FUNCTION validate_4_instances_planned_activity();

CREATE OR REPLACE FUNCTION validate_4_instances_course_instance()
RETURNS TRIGGER AS $$
DECLARE
    given_employee_id INTEGER;
BEGIN
    FOR given_employee_id IN
        SELECT DISTINCT teaching_allocation.employee_id
        FROM teaching_allocation
        INNER JOIN planned_activity ON planned_activity.id = teaching_allocation.planned_activity_id
        WHERE planned_activity.course_instance_id = NEW.id
    LOOP
        PERFORM validate_allocated_instances(given_employee_id, NEW.academic_period_id);
    END LOOP;

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trigger_4_instances_course_instance
AFTER UPDATE OF academic_period_id
ON course_instance
FOR EACH ROW
WHEN (OLD.academic_period_id IS DISTINCT FROM NEW.academic_period_id)
EXECUTE FUNCTION validate_4_instances_course_instance();

CREATE OR REPLACE FUNCTION validate_4_instances_each_study_period()
RETURNS TRIGGER AS $$
DECLARE
    new_instance_id INTEGER;
    new_academic_period_id INTEGER;
    current_value INTEGER;
    max_value INTEGER;
BEGIN
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
      AND course_instance.id <> new_instance_id;

    SELECT max_courses
    INTO max_value
    FROM allocation_rule
    ORDER BY id
    LIMIT 1;

    IF current_value >= max_value THEN
        RAISE EXCEPTION 'Problem: A teacher cannot be assigned to more than % course instances each academic period. Employee id: %, already allocated: %', max_value, NEW.employee_id, current_value;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trigger_4_instances_each_study_period
BEFORE INSERT OR UPDATE
ON teaching_allocation
FOR EACH ROW
EXECUTE FUNCTION validate_4_instances_each_study_period();

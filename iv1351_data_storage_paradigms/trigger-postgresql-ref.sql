CREATE OR REPLACE FUNCTION validate_4_instances_each_study_period()
RETURNS TRIGGER AS $$
DECLARE
    new_instance_id INTEGER;
    new_academic_period_id INTEGER;
    current_value INTEGER;
    max_value INTEGER;
BEGIN
    SELECT ci.id, ci.academic_period_id
    INTO new_instance_id, new_academic_period_id
    FROM planned_activity pa
    INNER JOIN course_instance ci ON ci.id = pa.course_instance_id
    WHERE pa.id = NEW.planned_activity_id;

    SELECT COUNT(DISTINCT ci.id)
    INTO current_value
    FROM teaching_allocation ta
    INNER JOIN planned_activity pa ON pa.id = ta.planned_activity_id
    INNER JOIN course_instance ci ON ci.id = pa.course_instance_id
    WHERE ta.employee_id = NEW.employee_id
      AND ci.academic_period_id = new_academic_period_id
      AND ci.id <> new_instance_id;

    SELECT max_courses
    INTO max_value
    FROM allocation_rule
    ORDER BY id
    LIMIT 1;

    IF current_value >= max_value THEN
        RAISE EXCEPTION 'Problem: A teacher cannot be assigned to more than % course instances each academic period. Employee id: %, already allocated: %',
            max_value, NEW.employee_id, current_value;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trigger_4_instances_each_study_period
BEFORE INSERT OR UPDATE
ON teaching_allocation
FOR EACH ROW
EXECUTE FUNCTION validate_4_instances_each_study_period();

CREATE OR REPLACE FUNCTION validate_4_instances_each_study_period()
RETURNS TRIGGER AS $$
DECLARE current_value INTEGER;
        max_value INTEGER;
BEGIN
    BEGIN
    SELECT COUNT(*) INTO current_value FROM (
        SELECT DISTINCT employee_id, academic_period_id FROM (
            (course_instance INNER JOIN
            planned_activity ON course_instance.id = planned_activity.course_instance_id)
            INNER JOIN teaching_allocation ON planned_activity.id = teaching_allocation.planned_activity_id)
            INNER JOIN employee ON teaching_allocation.employee_id = employee.id
            WHERE employee_id = NEW.employee_id);
    SELECT * INTO max_value FROM allocation_rule WHERE id = 1;
    END;
    IF current_value >= max_value THEN
        RAISE EXCEPTION '%', format('Problem: A teacher cannot be assigned to more than 4 course instance each academic period. maximum: %d, current: %d', max_value, current_value);
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE TRIGGER trigger_4_instances_each_study_period
BEFORE INSERT OR UPDATE
ON teaching_allocation
FOR EACH ROW
EXECUTE FUNCTION validate_4_instances_each_study_period();
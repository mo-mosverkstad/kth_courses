SELECT
    COALESCE(
        SUM(
            planned_activity.planned_hours * teaching_activity.multiplication_factor
        ),
        0
    ) AS total_planned_hours
FROM course_instance
INNER JOIN planned_activity
ON course_instance.id = planned_activity.course_instance_id
INNER JOIN teaching_activity
ON teaching_activity.id = planned_activity.teaching_activity_id
WHERE course_instance.instance_id = '2026-50000011';

SELECT
    COALESCE(
        SUM(
            teaching_allocation.allocation_hours * teaching_activity.multiplication_factor
        ),
    0) AS total_allocation_hours
FROM course_instance
INNER JOIN planned_activity
ON course_instance.id = planned_activity.course_instance_id
INNER JOIN teaching_activity
ON teaching_activity.id = planned_activity.teaching_activity_id
INNER JOIN teaching_allocation
ON teaching_allocation.planned_activity_id = planned_activity.id
WHERE course_instance.instance_id = '2026-50000011';

SELECT 
    AVG(latest.salary) AS average_salary
FROM (
    SELECT DISTINCT ON (employee_salary.employee_id) employee_salary.salary
    FROM employee_salary
    ORDER BY employee_salary.employee_id, employee_salary.valid_from DESC
) AS latest;

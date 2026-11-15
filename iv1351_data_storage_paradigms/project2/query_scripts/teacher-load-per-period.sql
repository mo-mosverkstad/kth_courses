-- Teacher load per period (5/day)

SELECT
    employee.employment_id AS employment_id,
    CONCAT(person.first_name, ' ', person.last_name) AS teacher_name,
    academic_period.academic_year AS academic_year,
    period.period_name AS period_number,
    COUNT(DISTINCT course_instance.id) AS number_of_courses,
    SUM(teaching_allocation.allocation_hours * teaching_activity.multiplication_factor) AS total_hours
FROM employee
INNER JOIN person
ON employee.person_id = person.id
INNER JOIN teaching_allocation
ON employee.id = teaching_allocation.employee_id
INNER JOIN planned_activity
ON planned_activity.id = teaching_allocation.planned_activity_id
INNER JOIN teaching_activity
ON teaching_activity.id = planned_activity.teaching_activity_id
INNER JOIN course_instance
ON planned_activity.course_instance_id = course_instance.id
INNER JOIN academic_period
ON course_instance.academic_period_id = academic_period.id
INNER JOIN period
ON academic_period.period_id = period.id

-- WHERE academic_period.academic_year = EXTRACT(YEAR FROM CURRENT_DATE)::int
WHERE academic_period.academic_year = 2025

GROUP BY
    employee.employment_id,
    person.first_name,
    person.last_name,
    academic_period.id,
    period.period_name

ORDER BY
    academic_year DESC,
    period_number,
    teacher_name;

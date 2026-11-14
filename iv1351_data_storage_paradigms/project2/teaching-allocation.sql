SELECT
    employee.employment_id AS employment_id,
    CONCAT(person.first_name, ' ', person.last_name) AS teacher_name,
    academic_period.academic_year AS academic_year,
    period.period_name AS period_number,
    COUNT(DISTINCT course_instance.id) AS number_of_courses
FROM employee
INNER JOIN person
ON employee.person_id = person.id
INNER JOIN teaching_allocation
ON employee.id = teaching_allocation.employee_id
INNER JOIN planned_activity
ON planned_activity.id = teaching_allocation.planned_activity_id
INNER JOIN course_instance
ON planned_activity.course_instance_id = course_instance.id
INNER JOIN academic_period
ON course_instance.academic_period_id = academic_period.id
INNER JOIN period
ON academic_period.period_id = period.id

-- WHERE CURRENT_DATE BETWEEN academic_period.start_date AND academic_period.end_date
-- Parameter part begin
WHERE academic_period.academic_year = 2026 AND period.period_name = 'P2'
-- Parameter part end

GROUP BY
    employee.employment_id,
    person.first_name,
    person.last_name,
    academic_period.id,
    period.period_name

-- Parameter part begin
HAVING COUNT(DISTINCT course_instance.id) > 1
-- Parameter part end

ORDER BY
    academic_year DESC,
    period_number,
    teacher_name;

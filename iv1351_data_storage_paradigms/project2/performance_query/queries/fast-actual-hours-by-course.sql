-- Actual allocated hours per teacher for one course instance (12/day).
-- Base tables, the course is selected in WHERE. Every join follows an existing index:
-- course (course_code), course_layout (course_id, version), course_instance (course_layout_id, ...),
-- planned_activity (course_instance_id, ...), teaching_allocation (planned_activity_id, employee_id).

SELECT
    course.course_code,
    course_instance.instance_id AS course_instance_id,
    course_layout.hp,
    CONCAT(person.first_name, ' ', person.last_name) AS teacher_name,
    job_title.job_title_name AS designation,

    SUM(CASE WHEN teaching_activity.activity_name = 'Lecture' THEN teaching_allocation.allocation_hours * teaching_activity.multiplication_factor ELSE 0 END) AS lecture_hours,
    SUM(CASE WHEN teaching_activity.activity_name = 'Tutorial' THEN teaching_allocation.allocation_hours * teaching_activity.multiplication_factor ELSE 0 END) AS tutorial_hours,
    SUM(CASE WHEN teaching_activity.activity_name = 'Lab' THEN teaching_allocation.allocation_hours * teaching_activity.multiplication_factor ELSE 0 END) AS lab_hours,
    SUM(CASE WHEN teaching_activity.activity_name = 'Seminar' THEN teaching_allocation.allocation_hours * teaching_activity.multiplication_factor ELSE 0 END) AS seminar_hours,
    SUM(CASE WHEN teaching_activity.activity_name = 'Others' THEN teaching_allocation.allocation_hours * teaching_activity.multiplication_factor ELSE 0 END) AS other_overhead_hours,
    SUM(CASE WHEN teaching_activity.activity_name = 'Administration' THEN teaching_allocation.allocation_hours * teaching_activity.multiplication_factor ELSE 0 END) AS administration_hours,
    SUM(CASE WHEN teaching_activity.activity_name = 'Examination' THEN teaching_allocation.allocation_hours * teaching_activity.multiplication_factor ELSE 0 END) AS examination_hours,
    SUM(teaching_allocation.allocation_hours * teaching_activity.multiplication_factor) AS total_hours

FROM course
INNER JOIN course_layout
    ON course_layout.course_id = course.id
INNER JOIN course_instance
    ON course_instance.course_layout_id = course_layout.id
INNER JOIN academic_period
    ON academic_period.id = course_instance.academic_period_id
INNER JOIN planned_activity
    ON planned_activity.course_instance_id = course_instance.id
INNER JOIN teaching_activity
    ON teaching_activity.id = planned_activity.teaching_activity_id
INNER JOIN teaching_allocation
    ON teaching_allocation.planned_activity_id = planned_activity.id
INNER JOIN employee
    ON employee.id = teaching_allocation.employee_id
INNER JOIN person
    ON person.id = employee.person_id
INNER JOIN job_title
    ON job_title.id = employee.job_title_id

-- Parameter part begin
WHERE course.course_code = 'IV1351'
  AND academic_period.academic_year = EXTRACT(YEAR FROM CURRENT_DATE)::int
-- Parameter part end

GROUP BY
    course.course_code,
    course_instance.instance_id,
    course_layout.hp,
    employee.id,
    person.first_name,
    person.last_name,
    job_title.job_title_name

ORDER BY
    course.course_code,
    course_instance.instance_id,
    teacher_name;

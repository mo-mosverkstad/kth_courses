SELECT
    course.course_code,
    course_instance.instance_id AS course_instance_id,
    course_layout.hp,
    CONCAT(person.first_name, ' ', person.last_name) AS teacher_name,
    job_title.job_title_name AS designation,

    SUM(CASE
        WHEN teaching_activity.activity_name = 'Lecture'
        THEN teaching_allocation.allocation_hours * teaching_activity.multiplication_factor
        ELSE 0
    END) AS lecture_hours,

    SUM(CASE
        WHEN teaching_activity.activity_name = 'Tutorial'
        THEN teaching_allocation.allocation_hours * teaching_activity.multiplication_factor
        ELSE 0
    END) AS tutorial_hours,

    SUM(CASE
        WHEN teaching_activity.activity_name = 'Lab'
        THEN teaching_allocation.allocation_hours * teaching_activity.multiplication_factor
        ELSE 0
    END) AS lab_hours,

    SUM(CASE
        WHEN teaching_activity.activity_name = 'Seminar'
        THEN teaching_allocation.allocation_hours * teaching_activity.multiplication_factor
        ELSE 0
    END) AS seminar_hours,

    SUM(CASE
        WHEN teaching_activity.activity_name = 'Others'
        THEN teaching_allocation.allocation_hours * teaching_activity.multiplication_factor
        ELSE 0
    END) AS other_overhead_hours,

    SUM(CASE
        WHEN teaching_activity.activity_name = 'Administration'
        THEN teaching_allocation.allocation_hours * teaching_activity.multiplication_factor
        ELSE 0
    END) AS administration_hours,

    SUM(CASE
        WHEN teaching_activity.activity_name = 'Examination'
        THEN teaching_allocation.allocation_hours * teaching_activity.multiplication_factor
        ELSE 0
    END) AS examination_hours,

    SUM(CASE
        WHEN teaching_activity.activity_name IN
             ('Lecture', 'Tutorial', 'Lab', 'Seminar', 'Others', 'Administration', 'Examination')
        THEN teaching_allocation.allocation_hours * teaching_activity.multiplication_factor
        ELSE 0
    END) AS total_hours

FROM course_layout
INNER JOIN course
    ON course_layout.course_id = course.id
INNER JOIN course_instance
    ON course_instance.course_layout_id = course_layout.id
INNER JOIN academic_period
    ON academic_period.id = course_instance.academic_period_id
INNER JOIN period
    ON period.id = academic_period.period_id

LEFT JOIN planned_activity
    ON planned_activity.course_instance_id = course_instance.id
INNER JOIN teaching_allocation
    ON planned_activity.id = teaching_allocation.planned_activity_id
INNER JOIN employee
    ON employee.id = teaching_allocation.employee_id
INNER JOIN person
    ON employee.person_id = person.id
INNER JOIN job_title
    ON employee.job_title_id = job_title.id

LEFT JOIN teaching_activity
    ON planned_activity.teaching_activity_id = teaching_activity.id

WHERE academic_period.academic_year = EXTRACT(YEAR FROM CURRENT_DATE)::int

GROUP BY
    course.course_code,
    course_instance.instance_id,
    course_layout.hp,
    employee.id,
    person.first_name,
    person.last_name,
    job_title.job_title_name

-- Parameter part begin
HAVING course.course_code = 'IV1351'
-- Parameter part end

ORDER BY
    course.course_code,
    course_instance.instance_id,
    teacher_name;

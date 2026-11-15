CREATE MATERIALIZED VIEW course_activity_view AS
SELECT
    course.course_code AS course_code,
    course_instance.instance_id AS instance_id,
    course_layout.hp AS hp,
    academic_period.academic_year AS academic_year,
    period.period_name AS period_number,
    course_instance.num_students AS num_students,
    teaching_activity.activity_name AS activity_name,

    CASE
        WHEN teaching_activity.activity_name IN
             ('Lecture', 'Tutorial', 'Lab', 'Seminar', 'Others')
        THEN planned_activity.planned_hours * teaching_activity.multiplication_factor
        WHEN teaching_activity.activity_name IN ('Administration', 'Examination')
        THEN (derived_activity_formula.base_hours
              + derived_activity_formula.hours_per_student * course_instance.num_students
              + derived_activity_formula.hours_per_hp * course_layout.hp)
             * teaching_activity.multiplication_factor
        ELSE 0
    END AS total_planned_hours

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
LEFT JOIN teaching_activity
    ON planned_activity.teaching_activity_id = teaching_activity.id
LEFT JOIN derived_activity_formula
    ON derived_activity_formula.teaching_activity_id = teaching_activity.id
GROUP BY
    course_layout.course_code,
    course_instance.instance_id,
    academic_period.id,
    period.period_name,
    teaching_activity.activity_name,

WITH DATA;

CREATE MATERIALIZED VIEW employee_view AS
SELECT  
    employee.employment_id AS employment_id,
    CONCAT(person.first_name, ' ', person.last_name) AS teacher_name,
    job_title.job_title_name AS designation

FROM employee
INNER JOIN person
    ON employee.person_id = person.id
INNER JOIN job_title
    ON employee.job_title_id = job_title.id
WITH DATA;
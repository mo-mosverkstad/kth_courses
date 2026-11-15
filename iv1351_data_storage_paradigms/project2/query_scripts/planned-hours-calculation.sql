SELECT
    course.course_code,
    course_instance.instance_id AS course_instance_id,
    course_layout.hp,
    period.period_name AS period,
    course_instance.num_students AS students,

    SUM(CASE
        WHEN teaching_activity.activity_name = 'Lecture'
        THEN planned_activity.planned_hours * teaching_activity.multiplication_factor
        ELSE 0
    END) AS lecture_hours,

    SUM(CASE
        WHEN teaching_activity.activity_name = 'Tutorial'
        THEN planned_activity.planned_hours * teaching_activity.multiplication_factor
        ELSE 0
    END) AS tutorial_hours,

    SUM(CASE
        WHEN teaching_activity.activity_name = 'Lab'
        THEN planned_activity.planned_hours * teaching_activity.multiplication_factor
        ELSE 0
    END) AS lab_hours,

    SUM(CASE
        WHEN teaching_activity.activity_name = 'Seminar'
        THEN planned_activity.planned_hours * teaching_activity.multiplication_factor
        ELSE 0
    END) AS seminar_hours,

    SUM(CASE
        WHEN teaching_activity.activity_name = 'Others'
        THEN planned_activity.planned_hours * teaching_activity.multiplication_factor
        ELSE 0
    END) AS other_overhead_hours,

    SUM(CASE
        WHEN teaching_activity.activity_name = 'Administration'
        THEN (derived_activity_formula.base_hours
              + derived_activity_formula.hours_per_student * course_instance.num_students
              + derived_activity_formula.hours_per_hp * course_layout.hp)
             * teaching_activity.multiplication_factor
        ELSE 0
    END) AS admin_hours,

    SUM(CASE
        WHEN teaching_activity.activity_name = 'Examination'
        THEN (derived_activity_formula.base_hours
              + derived_activity_formula.hours_per_student * course_instance.num_students
              + derived_activity_formula.hours_per_hp * course_layout.hp)
             * teaching_activity.multiplication_factor
        ELSE 0
    END) AS exam_hours,

    SUM(CASE
        WHEN teaching_activity.activity_name IN
             ('Lecture', 'Tutorial', 'Lab', 'Seminar', 'Others')
        THEN planned_activity.planned_hours * teaching_activity.multiplication_factor
        WHEN teaching_activity.activity_name IN ('Administration', 'Examination')
        THEN (derived_activity_formula.base_hours
              + derived_activity_formula.hours_per_student * course_instance.num_students
              + derived_activity_formula.hours_per_hp * course_layout.hp)
             * teaching_activity.multiplication_factor
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
LEFT JOIN teaching_activity
    ON planned_activity.teaching_activity_id = teaching_activity.id
LEFT JOIN derived_activity_formula
    ON derived_activity_formula.teaching_activity_id = teaching_activity.id

-- WHERE academic_period.academic_year = EXTRACT(YEAR FROM CURRENT_DATE)::int
WHERE academic_period.academic_year = 2025

GROUP BY
    course.course_code,
    course_instance.instance_id,
    course_layout.hp,
    period.period_name,
    course_instance.num_students

ORDER BY
    course.course_code,
    course_instance.instance_id;

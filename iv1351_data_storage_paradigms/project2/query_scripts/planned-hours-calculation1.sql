SELECT
course.course_code,
course_instance.instance_id,
course_layout.hp,
period.period_name,
course_instance.num_students,
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
    THEN planned_activity.planned_hours * 1
    ELSE 0
END) AS other_overhead_hours,

SUM(CASE
    WHEN teaching_activity.activity_name = 'Exam'
    THEN (derived_activity_formula.base_hours + derived_activity_formula.hours_per_student * course_instance.num_students + derived_activity_formula.hours_per_hp * course_layout.hp) * teaching_activity.multiplication_factor
    ELSE 0
END) AS exam_hours,

SUM(CASE
    WHEN teaching_activity.activity_name = 'Admin'
    THEN (derived_activity_formula.base_hours + derived_activity_formula.hours_per_student * course_instance.num_students + derived_activity_formula.hours_per_hp * course_layout.hp) * teaching_activity.multiplication_factor
    ELSE 0
END) AS admin_hours


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
ON teaching_activity.id = derived_activity_formula.teaching_activity_id

GROUP BY
    course.course_code,
    course_instance.instance_id,
    course_layout.hp,
    period.period_name,
    course_instance.num_students;

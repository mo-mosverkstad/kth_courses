-- Planned hours per course instance (8/day), read from course_activity_view

SELECT
    course_activity_view.course_code,
    course_activity_view.instance_id AS course_instance_id,
    course_activity_view.hp,
    course_activity_view.period_number AS period,
    course_activity_view.num_students AS students,

    SUM(CASE WHEN course_activity_view.activity_name = 'Lecture' THEN course_activity_view.planned_hours ELSE 0 END) AS lecture_hours,
    SUM(CASE WHEN course_activity_view.activity_name = 'Tutorial' THEN course_activity_view.planned_hours ELSE 0 END) AS tutorial_hours,
    SUM(CASE WHEN course_activity_view.activity_name = 'Lab' THEN course_activity_view.planned_hours ELSE 0 END) AS lab_hours,
    SUM(CASE WHEN course_activity_view.activity_name = 'Seminar' THEN course_activity_view.planned_hours ELSE 0 END) AS seminar_hours,
    SUM(CASE WHEN course_activity_view.activity_name = 'Others' THEN course_activity_view.planned_hours ELSE 0 END) AS other_overhead_hours,
    SUM(CASE WHEN course_activity_view.activity_name = 'Administration' THEN course_activity_view.planned_hours ELSE 0 END) AS admin_hours,
    SUM(CASE WHEN course_activity_view.activity_name = 'Examination' THEN course_activity_view.planned_hours ELSE 0 END) AS exam_hours,
    SUM(course_activity_view.planned_hours) AS total_hours

FROM course_activity_view

-- Parameter part begin
WHERE course_activity_view.academic_year = 2025
-- Parameter part end

GROUP BY
    course_activity_view.course_instance_id,
    course_activity_view.course_code,
    course_activity_view.instance_id,
    course_activity_view.hp,
    course_activity_view.period_number,
    course_activity_view.num_students

ORDER BY
    course_activity_view.course_code,
    course_activity_view.instance_id;

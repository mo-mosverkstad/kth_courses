-- Planned hours per course instance (8/day), read from course_instance_planned_view.
-- The view is already one row per course instance, so there is no grouping left to do.

SELECT
    course_instance_planned_view.course_code,
    course_instance_planned_view.instance_id AS course_instance_id,
    course_instance_planned_view.hp,
    course_instance_planned_view.period_number AS period,
    course_instance_planned_view.num_students AS students,

    course_instance_planned_view.lecture_hours,
    course_instance_planned_view.tutorial_hours,
    course_instance_planned_view.lab_hours,
    course_instance_planned_view.seminar_hours,
    course_instance_planned_view.other_overhead_hours,
    course_instance_planned_view.admin_hours,
    course_instance_planned_view.exam_hours,
    course_instance_planned_view.total_hours

FROM course_instance_planned_view

-- Parameter part begin
WHERE course_instance_planned_view.academic_year = 2025
-- Parameter part end

ORDER BY
    course_instance_planned_view.course_code,
    course_instance_planned_view.instance_id;

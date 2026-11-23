-- Planned hours per course instance (8/day), read from course_instance_planned_json_view.
-- The view stores one key-value map per course instance, so there is no grouping left to
-- do. The activity names appear here, in the presentation, and not in the view.
-- A new teaching activity needs no change to the view, only one more line below.

SELECT
    course_instance_planned_json_view.course_code,
    course_instance_planned_json_view.instance_id AS course_instance_id,
    course_instance_planned_json_view.hp,
    course_instance_planned_json_view.period_number AS period,
    course_instance_planned_json_view.num_students AS students,

    COALESCE((hours_per_activity->>'Lecture')::numeric, 0) AS lecture_hours,
    COALESCE((hours_per_activity->>'Tutorial')::numeric, 0) AS tutorial_hours,
    COALESCE((hours_per_activity->>'Lab')::numeric, 0) AS lab_hours,
    COALESCE((hours_per_activity->>'Seminar')::numeric, 0) AS seminar_hours,
    COALESCE((hours_per_activity->>'Others')::numeric, 0) AS other_overhead_hours,
    COALESCE((hours_per_activity->>'Administration')::numeric, 0) AS admin_hours,
    COALESCE((hours_per_activity->>'Examination')::numeric, 0) AS exam_hours,
    course_instance_planned_json_view.total_hours

FROM course_instance_planned_json_view

-- Parameter part begin
WHERE course_instance_planned_json_view.academic_year = 2025
-- Parameter part end

ORDER BY
    course_instance_planned_json_view.course_code,
    course_instance_planned_json_view.instance_id;

-- Course instances where planned and allocated hours differ by more than 15% (3/day),
-- read from course_instance_mismatch_view. Both sides are already summed per course
-- instance in the view, so the query only has to compare them.

SELECT
    course_instance_mismatch_view.course_instance_id,
    course_instance_mismatch_view.planned_instance_hours,
    course_instance_mismatch_view.allocated_instance_hours,
    (course_instance_mismatch_view.allocated_instance_hours - course_instance_mismatch_view.planned_instance_hours)
        / course_instance_mismatch_view.planned_instance_hours AS difference_percentage
FROM course_instance_mismatch_view
WHERE ABS(
    (course_instance_mismatch_view.allocated_instance_hours - course_instance_mismatch_view.planned_instance_hours)
    / course_instance_mismatch_view.planned_instance_hours
) > .15;

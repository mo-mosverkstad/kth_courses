-- Course instances where planned and allocated hours differ by more than 15% (3/day).
-- Planned hours come from course_activity_view, the allocations are summed per planned
-- activity first (in primary key order of teaching_allocation) and then per course instance.

SELECT
    course_activity_view.course_instance_id,
    SUM(course_activity_view.planned_hours) AS planned_instance_hours,
    SUM(allocated.allocation_hours * course_activity_view.multiplication_factor) AS allocated_instance_hours,
    (SUM(allocated.allocation_hours * course_activity_view.multiplication_factor) - SUM(course_activity_view.planned_hours))
        / SUM(course_activity_view.planned_hours) AS difference_percentage
FROM course_activity_view
INNER JOIN (
    SELECT
        teaching_allocation.planned_activity_id,
        SUM(teaching_allocation.allocation_hours) AS allocation_hours
    FROM teaching_allocation
    GROUP BY teaching_allocation.planned_activity_id
) AS allocated
    ON allocated.planned_activity_id = course_activity_view.planned_activity_id
GROUP BY course_activity_view.course_instance_id
HAVING ABS(
    (SUM(allocated.allocation_hours * course_activity_view.multiplication_factor) - SUM(course_activity_view.planned_hours))
    / SUM(course_activity_view.planned_hours)
) > .15;

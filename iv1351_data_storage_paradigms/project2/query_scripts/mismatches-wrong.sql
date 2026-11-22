-- Deliberately incorrect version of mismatches.sql.
-- The planned hours are summed over the joined allocation rows, so a planned activity
-- with several allocated teachers has its planned hours counted once per teacher.

SELECT
    course_instance.id AS course_instance_id,
    SUM(planned_activity.planned_hours * teaching_activity.multiplication_factor) AS planned_instance_hours,
    SUM(teaching_allocation.allocation_hours * teaching_activity.multiplication_factor) AS allocated_instance_hours,
    (
        SUM(teaching_allocation.allocation_hours * teaching_activity.multiplication_factor)
        - SUM(planned_activity.planned_hours * teaching_activity.multiplication_factor)
    ) / SUM(planned_activity.planned_hours * teaching_activity.multiplication_factor) AS difference_percentage
FROM
course_instance
INNER JOIN
planned_activity
ON course_instance.id = planned_activity.course_instance_id
INNER JOIN
teaching_allocation
ON teaching_allocation.planned_activity_id = planned_activity.id
LEFT JOIN
teaching_activity
ON teaching_activity.id = planned_activity.teaching_activity_id
GROUP BY course_instance.id
HAVING ABS(
    (
        SUM(teaching_allocation.allocation_hours * teaching_activity.multiplication_factor)
        - SUM(planned_activity.planned_hours * teaching_activity.multiplication_factor)
    ) / SUM(planned_activity.planned_hours * teaching_activity.multiplication_factor)
) > .15;

SELECT
    activity_hours.course_instance_id,
    SUM(activity_hours.planned_activity_hours) AS planned_instance_hours,
    SUM(activity_hours.allocated_activity_hours) AS allocated_instance_hours,
    (SUM(activity_hours.allocated_activity_hours) - SUM(activity_hours.planned_activity_hours))/SUM(activity_hours.planned_activity_hours) AS difference_percentage
FROM (
    SELECT
        course_instance.id AS course_instance_id,
        COALESCE(
            planned_activity.planned_hours,
            derived_activity_formula.base_hours
            + derived_activity_formula.hours_per_student * course_instance.num_students
            + derived_activity_formula.hours_per_hp * course_layout.hp
        ) * teaching_activity.multiplication_factor AS planned_activity_hours,
        SUM(teaching_allocation.allocation_hours) * teaching_activity.multiplication_factor AS allocated_activity_hours
    FROM
    course_instance
    INNER JOIN
    planned_activity
    ON course_instance.id = planned_activity.course_instance_id
    INNER JOIN
    teaching_allocation
    ON teaching_allocation.planned_activity_id = planned_activity.id
    INNER JOIN
    course_layout
    ON course_layout.id = course_instance.course_layout_id
    LEFT JOIN
    teaching_activity
    ON teaching_activity.id = planned_activity.teaching_activity_id
    LEFT JOIN
    derived_activity_formula
    ON teaching_activity.id = derived_activity_formula.teaching_activity_id
    GROUP BY
    course_layout.id,
    course_instance.id,
    planned_activity.id,
    teaching_activity.id,
    derived_activity_formula.id
) AS activity_hours
GROUP BY activity_hours.course_instance_id
HAVING ABS((SUM(activity_hours.allocated_activity_hours) - SUM(activity_hours.planned_activity_hours))/SUM(activity_hours.planned_activity_hours)) > .15;

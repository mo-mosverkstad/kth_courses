SELECT
    course_instance.id AS course_instance_id,
    SUM(
        COALESCE(
            planned_activity.planned_hours,
            derived_activity_formula.base_hours
            + derived_activity_formula.hours_per_student * course_instance.num_students
            + derived_activity_formula.hours_per_hp * course_layout.hp
        ) * teaching_activity.multiplication_factor
    ) AS planned_instance_hours,
    SUM(teaching_allocation.allocation_hours * teaching_activity.multiplication_factor) AS allocated_instance_hours,
    (
        SUM(teaching_allocation.allocation_hours * teaching_activity.multiplication_factor)
        - SUM(
            COALESCE(
                planned_activity.planned_hours,
                derived_activity_formula.base_hours
                + derived_activity_formula.hours_per_student * course_instance.num_students
                + derived_activity_formula.hours_per_hp * course_layout.hp
            ) * teaching_activity.multiplication_factor
        )
    ) / SUM(
        COALESCE(
            planned_activity.planned_hours,
            derived_activity_formula.base_hours
            + derived_activity_formula.hours_per_student * course_instance.num_students
            + derived_activity_formula.hours_per_hp * course_layout.hp
        ) * teaching_activity.multiplication_factor
    ) AS difference_percentage
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
GROUP BY course_instance.id
HAVING ABS(
    (
        SUM(teaching_allocation.allocation_hours * teaching_activity.multiplication_factor)
        - SUM(
            COALESCE(
                planned_activity.planned_hours,
                derived_activity_formula.base_hours
                + derived_activity_formula.hours_per_student * course_instance.num_students
                + derived_activity_formula.hours_per_hp * course_layout.hp
            ) * teaching_activity.multiplication_factor
        )
    ) / SUM(
        COALESCE(
            planned_activity.planned_hours,
            derived_activity_formula.base_hours
            + derived_activity_formula.hours_per_student * course_instance.num_students
            + derived_activity_formula.hours_per_hp * course_layout.hp
        ) * teaching_activity.multiplication_factor
    )
) > .15;

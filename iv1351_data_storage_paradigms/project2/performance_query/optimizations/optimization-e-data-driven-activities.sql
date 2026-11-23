-- Optimization E: like optimization D, but no teaching activity name is written in the view.
--
-- optimization D pivots the planned hours into one fixed column per teaching activity, which
-- means that every activity name is hardcoded in the view as a string literal. That has two
-- consequences. A teaching activity that is added to the table teaching_activity afterwards
-- gets no column, and it is not counted in total_hours either, since that sum also lists the
-- seven names. The project description requires the database to be flexible enough to add
-- more activities, so the view contradicts the schema it is built on.
--
-- E stores the same data as one key-value map per course instance instead, where the keys are
-- whatever names exist in teaching_activity. Adding a new activity needs no change to the
-- view at all, and it is included in total_hours automatically. The activity names appear
-- only in the query that reads the view, when it picks the keys it wants to display.
--
-- Everything apart from the planned hours view is identical to optimization D, so that the
-- comparison measures only this one difference.
--
-- Queries: ../queries/query-e-planned-hours.sql (planned hours)
--          ../queries/query-d-mismatches.sql  (unchanged from D)
-- Run optimization-a-baseline.sql to remove everything again.

DROP MATERIALIZED VIEW IF EXISTS teacher_period_load_view;
DROP MATERIALIZED VIEW IF EXISTS course_instance_planned_view;
DROP MATERIALIZED VIEW IF EXISTS course_instance_planned_json_view;
DROP MATERIALIZED VIEW IF EXISTS course_instance_mismatch_view;
DROP MATERIALIZED VIEW IF EXISTS course_activity_view;
DROP INDEX IF EXISTS idx_teaching_allocation_employee;
DROP INDEX IF EXISTS idx_course_instance_academic_period;


-- One row per course instance. The planned hours of every teaching activity are stored in
-- a JSONB map, keyed by the activity name as it is spelled in the table teaching_activity.
-- Used by: planned hours per course instance (8/day)

CREATE MATERIALIZED VIEW course_instance_planned_json_view AS
SELECT
    course_instance.id AS course_instance_id,
    course.course_code AS course_code,
    course_instance.instance_id AS instance_id,
    course_layout.hp AS hp,
    academic_period.academic_year AS academic_year,
    period.period_name AS period_number,
    course_instance.num_students AS num_students,

    COALESCE(
        jsonb_object_agg(
            teaching_activity.activity_name,
            planned_activity.planned_hours * teaching_activity.multiplication_factor
        ) FILTER (WHERE teaching_activity.activity_name IS NOT NULL),
        '{}'::jsonb
    ) AS hours_per_activity,

    COALESCE(
        SUM(planned_activity.planned_hours * teaching_activity.multiplication_factor),
        0
    ) AS total_hours

FROM course_instance
INNER JOIN course_layout
    ON course_layout.id = course_instance.course_layout_id
INNER JOIN course
    ON course.id = course_layout.course_id
INNER JOIN academic_period
    ON academic_period.id = course_instance.academic_period_id
INNER JOIN period
    ON period.id = academic_period.period_id
LEFT JOIN planned_activity
    ON planned_activity.course_instance_id = course_instance.id
LEFT JOIN teaching_activity
    ON teaching_activity.id = planned_activity.teaching_activity_id

GROUP BY
    course_instance.id,
    course.course_code,
    course_instance.instance_id,
    course_layout.hp,
    academic_period.academic_year,
    period.period_name,
    course_instance.num_students

WITH DATA;

CREATE UNIQUE INDEX course_instance_planned_json_view_key
    ON course_instance_planned_json_view (course_instance_id);
CREATE INDEX course_instance_planned_json_view_year_period
    ON course_instance_planned_json_view (academic_year, period_number);


-- Identical to optimization D from here on.

CREATE MATERIALIZED VIEW course_instance_mismatch_view AS
SELECT
    activity_hours.course_instance_id AS course_instance_id,
    SUM(activity_hours.planned_activity_hours) AS planned_instance_hours,
    SUM(activity_hours.allocated_activity_hours) AS allocated_instance_hours
FROM (
    SELECT
        planned_activity.course_instance_id AS course_instance_id,
        planned_activity.planned_hours * teaching_activity.multiplication_factor AS planned_activity_hours,
        SUM(teaching_allocation.allocation_hours) * teaching_activity.multiplication_factor AS allocated_activity_hours
    FROM planned_activity
    INNER JOIN teaching_allocation
        ON teaching_allocation.planned_activity_id = planned_activity.id
    INNER JOIN teaching_activity
        ON teaching_activity.id = planned_activity.teaching_activity_id
    GROUP BY
        planned_activity.course_instance_id,
        planned_activity.id,
        teaching_activity.id
) AS activity_hours
GROUP BY activity_hours.course_instance_id

WITH DATA;

CREATE UNIQUE INDEX course_instance_mismatch_view_key
    ON course_instance_mismatch_view (course_instance_id);


CREATE MATERIALIZED VIEW teacher_period_load_view AS
SELECT
    employee.id AS employee_id,
    employee.employment_id AS employment_id,
    CONCAT(person.first_name, ' ', person.last_name) AS teacher_name,
    academic_period.id AS academic_period_id,
    academic_period.academic_year AS academic_year,
    period.period_name AS period_number,
    COUNT(DISTINCT course_instance.id) AS number_of_courses,
    SUM(teaching_allocation.allocation_hours * teaching_activity.multiplication_factor) AS total_hours

FROM teaching_allocation
INNER JOIN employee
    ON employee.id = teaching_allocation.employee_id
INNER JOIN person
    ON person.id = employee.person_id
INNER JOIN planned_activity
    ON planned_activity.id = teaching_allocation.planned_activity_id
INNER JOIN teaching_activity
    ON teaching_activity.id = planned_activity.teaching_activity_id
INNER JOIN course_instance
    ON course_instance.id = planned_activity.course_instance_id
INNER JOIN academic_period
    ON academic_period.id = course_instance.academic_period_id
INNER JOIN period
    ON period.id = academic_period.period_id

GROUP BY
    employee.id,
    employee.employment_id,
    person.first_name,
    person.last_name,
    academic_period.id,
    academic_period.academic_year,
    period.period_name

WITH DATA;

CREATE UNIQUE INDEX teacher_period_load_view_key
    ON teacher_period_load_view (employee_id, academic_period_id);
CREATE INDEX teacher_period_load_view_year_period
    ON teacher_period_load_view (academic_year, period_number);


CREATE INDEX idx_teaching_allocation_employee
    ON teaching_allocation (employee_id);

ANALYZE course_instance_planned_json_view;
ANALYZE course_instance_mismatch_view;
ANALYZE teacher_period_load_view;
ANALYZE teaching_allocation;

-- Candidate D: materialized views at the grain of the result of each query.
-- This is the candidate that was chosen, so this file is also the solution.
--
-- Every view stores one row per row of the result of the query that reads it, which means
-- that the query has no grouping left to do at all. That is the reason D is the only
-- candidate that changes the order of magnitude. Candidate C stores one row per planned
-- activity instead, which is the grain of the table it reads from, so it can only remove
-- joins and never the aggregation. See RESULTS.md.
--
-- Queries: performance_query/queries/fast-*.sql
-- Run candidate-a-no-optimisation.sql to remove everything again.
--
-- Can be re-run at any time, and does not care which candidate is active.

DROP MATERIALIZED VIEW IF EXISTS teacher_period_load_view;
DROP MATERIALIZED VIEW IF EXISTS course_instance_planned_view;
DROP MATERIALIZED VIEW IF EXISTS course_instance_planned_json_view;
DROP MATERIALIZED VIEW IF EXISTS course_instance_mismatch_view;
DROP MATERIALIZED VIEW IF EXISTS course_activity_view;
DROP INDEX IF EXISTS idx_teaching_allocation_employee;
DROP INDEX IF EXISTS idx_course_instance_academic_period;


-- One row per course instance, with the planned hours already summed per teaching activity.
-- Used by: planned hours per course instance (8/day)

CREATE MATERIALIZED VIEW course_instance_planned_view AS
SELECT
    course_instance.id AS course_instance_id,
    course.course_code AS course_code,
    course_instance.instance_id AS instance_id,
    course_layout.hp AS hp,
    academic_period.academic_year AS academic_year,
    period.period_name AS period_number,
    course_instance.num_students AS num_students,

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
        THEN planned_activity.planned_hours * teaching_activity.multiplication_factor
        ELSE 0
    END) AS other_overhead_hours,

    SUM(CASE
        WHEN teaching_activity.activity_name = 'Administration'
        THEN planned_activity.planned_hours * teaching_activity.multiplication_factor
        ELSE 0
    END) AS admin_hours,

    SUM(CASE
        WHEN teaching_activity.activity_name = 'Examination'
        THEN planned_activity.planned_hours * teaching_activity.multiplication_factor
        ELSE 0
    END) AS exam_hours,

    SUM(CASE
        WHEN teaching_activity.activity_name IN
             ('Lecture', 'Tutorial', 'Lab', 'Seminar', 'Others',
              'Administration', 'Examination')
        THEN planned_activity.planned_hours * teaching_activity.multiplication_factor
        ELSE 0
    END) AS total_hours

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

CREATE UNIQUE INDEX course_instance_planned_view_key
    ON course_instance_planned_view (course_instance_id);
CREATE INDEX course_instance_planned_view_year_period
    ON course_instance_planned_view (academic_year, period_number);


-- One row per course instance, with the planned and the allocated hours already summed.
-- Only planned activities that have at least one allocation are included, which is the
-- same set of rows that the mismatch query compares.
-- Used by: course instances where planned and allocated hours differ by more than 15% (3/day)

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


-- One row per teacher and academic period.
-- Used by: teacher load per period (5/day), teachers with more than N instances (20/day)

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


-- Index on the base table for the per-teacher lookups (12/day).
-- planned_activity.course_instance_id is already the first column of
-- UNIQUE (course_instance_id, teaching_activity_id), so it needs no extra index.

CREATE INDEX idx_teaching_allocation_employee
    ON teaching_allocation (employee_id);

ANALYZE course_instance_planned_view;
ANALYZE course_instance_mismatch_view;
ANALYZE teacher_period_load_view;
ANALYZE teaching_allocation;

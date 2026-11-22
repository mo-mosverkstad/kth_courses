-- Materialized views and indexes for the query workload.
-- Run after the create, trigger and insert scripts. Can be re-run.

DROP MATERIALIZED VIEW IF EXISTS teacher_period_load_view;
DROP MATERIALIZED VIEW IF EXISTS course_activity_view;
DROP INDEX IF EXISTS idx_teaching_allocation_employee;


-- One row per planned activity, with the planned hours including the multiplication factor.
-- Used by: planned hours per course instance (8/day), planned side of the mismatches (3/day)

CREATE MATERIALIZED VIEW course_activity_view AS
SELECT
    planned_activity.id AS planned_activity_id,
    course_instance.id AS course_instance_id,
    course.course_code AS course_code,
    course_instance.instance_id AS instance_id,
    course_layout.hp AS hp,
    academic_period.academic_year AS academic_year,
    period.period_name AS period_number,
    course_instance.num_students AS num_students,
    teaching_activity.activity_name AS activity_name,
    teaching_activity.multiplication_factor AS multiplication_factor,
    planned_activity.planned_hours * teaching_activity.multiplication_factor AS planned_hours

FROM planned_activity
INNER JOIN course_instance
    ON course_instance.id = planned_activity.course_instance_id
INNER JOIN course_layout
    ON course_layout.id = course_instance.course_layout_id
INNER JOIN course
    ON course.id = course_layout.course_id
INNER JOIN academic_period
    ON academic_period.id = course_instance.academic_period_id
INNER JOIN period
    ON period.id = academic_period.period_id
INNER JOIN teaching_activity
    ON teaching_activity.id = planned_activity.teaching_activity_id

WITH DATA;

CREATE UNIQUE INDEX course_activity_view_planned_activity
    ON course_activity_view (planned_activity_id);
CREATE INDEX course_activity_view_year_period
    ON course_activity_view (academic_year, period_number);

-- Removed index for view course_activity_view_instance
-- CREATE INDEX course_activity_view_instance ON course_activity_view (instance_id);


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

ANALYZE course_activity_view;
ANALYZE teacher_period_load_view;
ANALYZE teaching_allocation;

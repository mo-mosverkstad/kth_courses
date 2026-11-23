-- Candidate C: a materialized view at the grain of planned_activity.
--
-- This was the first solution. It stores one row per planned activity, with the
-- multiplication factor applied and the lookup tables already joined in, which removes
-- the joins of the workload queries but not their grouping, since the view has exactly as
-- many rows as the table it reads from.
--
-- It was rejected. The joins it removes are against small tables that are already cached,
-- while its own rows are 67 bytes against 16 bytes in planned_activity, so reading one
-- academic year out of it moves more data than reading the base tables. See RESULTS.md.
--
-- Queries: candidates/queries/cand-planned-hours-activity-grain.sql
--          candidates/queries/cand-mismatches-activity-grain.sql

DROP MATERIALIZED VIEW IF EXISTS teacher_period_load_view;
DROP MATERIALIZED VIEW IF EXISTS course_instance_planned_view;
DROP MATERIALIZED VIEW IF EXISTS course_instance_planned_json_view;
DROP MATERIALIZED VIEW IF EXISTS course_instance_mismatch_view;
DROP MATERIALIZED VIEW IF EXISTS course_activity_view;
DROP INDEX IF EXISTS idx_teaching_allocation_employee;
DROP INDEX IF EXISTS idx_course_instance_academic_period;

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

ANALYZE course_activity_view;

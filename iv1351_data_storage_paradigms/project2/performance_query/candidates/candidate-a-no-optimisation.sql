-- Candidate A: no optimisation at all. This is the baseline that every other candidate
-- is compared against. The workload queries in query_scripts/ read the base tables only.
--
-- Switching to this state removes every object that the other candidates create, so the
-- file can be run at any time regardless of which candidate is active.

DROP MATERIALIZED VIEW IF EXISTS teacher_period_load_view;
DROP MATERIALIZED VIEW IF EXISTS course_instance_planned_view;
DROP MATERIALIZED VIEW IF EXISTS course_instance_planned_json_view;
DROP MATERIALIZED VIEW IF EXISTS course_instance_mismatch_view;
DROP MATERIALIZED VIEW IF EXISTS course_activity_view;
DROP INDEX IF EXISTS idx_teaching_allocation_employee;
DROP INDEX IF EXISTS idx_course_instance_academic_period;

ANALYZE course_instance;
ANALYZE planned_activity;
ANALYZE teaching_allocation;

-- Optimization A: the baseline, that is no optimization at all. Every other optimization is
-- measured against this state. The workload queries in ../../query_scripts/ read the base
-- tables only, with no materialized view and no extra index.
--
-- This file also serves as the way back: it removes every object that any of the other
-- optimizations create, so it can be run at any time regardless of which one is active.

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

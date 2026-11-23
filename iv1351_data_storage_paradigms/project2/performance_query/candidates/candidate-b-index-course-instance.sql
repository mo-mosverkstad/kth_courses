-- Candidate B: one plain index, no materialized view.
--
-- course_instance.academic_period_id is only the second column of
-- UNIQUE (course_layout_id, academic_period_id), so no existing index can be used to go
-- from an academic period to its course instances. Every report that filters on an
-- academic year has to make that step, which is why this is the cheapest candidate that
-- could possibly help. It costs about 9 MB and no refresh at all.
--
-- The workload queries in query_scripts/ are used unchanged, since an index does not
-- require the query to be rewritten.

DROP MATERIALIZED VIEW IF EXISTS teacher_period_load_view;
DROP MATERIALIZED VIEW IF EXISTS course_instance_planned_view;
DROP MATERIALIZED VIEW IF EXISTS course_instance_planned_json_view;
DROP MATERIALIZED VIEW IF EXISTS course_instance_mismatch_view;
DROP MATERIALIZED VIEW IF EXISTS course_activity_view;
DROP INDEX IF EXISTS idx_teaching_allocation_employee;
DROP INDEX IF EXISTS idx_course_instance_academic_period;

CREATE INDEX idx_course_instance_academic_period
    ON course_instance (academic_period_id);

ANALYZE course_instance;

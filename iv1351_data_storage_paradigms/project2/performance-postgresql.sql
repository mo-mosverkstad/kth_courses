-- Capture baseline plans before this script with EXPLAIN (ANALYZE, BUFFERS).
-- Run after queries.sql has been reviewed and the scale-data script loaded.

CREATE INDEX IF NOT EXISTS ix_academic_period_year_period
    ON academic_period (academic_year, period_id);
CREATE INDEX IF NOT EXISTS ix_course_instance_period
    ON course_instance (academic_period_id, id);
CREATE INDEX IF NOT EXISTS ix_planned_activity_instance
    ON planned_activity (course_instance_id, teaching_activity_id);
CREATE INDEX IF NOT EXISTS ix_allocation_employee_activity
    ON teaching_allocation (employee_id, planned_activity_id) INCLUDE (allocation_hours);

CREATE MATERIALIZED VIEW mv_planned_instance_hours AS
SELECT pa.course_instance_id,
       sum((CASE WHEN daf.id IS NULL THEN pa.planned_hours::numeric
                 ELSE round(daf.base_hours + daf.hours_per_student * ci.num_students
                          + daf.hours_per_hp * cl.hp) END)
           * ta.multiplication_factor) AS planned_hours
FROM planned_activity pa
JOIN course_instance ci ON ci.id = pa.course_instance_id
JOIN course_layout cl ON cl.id = ci.course_layout_id
JOIN teaching_activity ta ON ta.id = pa.teaching_activity_id
LEFT JOIN derived_activity_formula daf ON daf.teaching_activity_id = ta.id
GROUP BY pa.course_instance_id;
CREATE UNIQUE INDEX ix_mv_planned_instance ON mv_planned_instance_hours (course_instance_id);

CREATE MATERIALIZED VIEW mv_allocated_instance_hours AS
SELECT pa.course_instance_id,
       sum(al.allocation_hours * ta.multiplication_factor) AS allocated_hours
FROM teaching_allocation al
JOIN planned_activity pa ON pa.id = al.planned_activity_id
JOIN teaching_activity ta ON ta.id = pa.teaching_activity_id
GROUP BY pa.course_instance_id;
CREATE UNIQUE INDEX ix_mv_allocated_instance ON mv_allocated_instance_hours (course_instance_id);

-- Teacher load, by period and employee, supports the period workload query.
CREATE MATERIALIZED VIEW mv_teacher_period_load AS
SELECT ci.academic_period_id, al.employee_id,
       count(DISTINCT ci.id) AS course_instance_count,
       sum(al.allocation_hours * ta.multiplication_factor) AS workload_hours
FROM teaching_allocation al
JOIN planned_activity pa ON pa.id = al.planned_activity_id
JOIN teaching_activity ta ON ta.id = pa.teaching_activity_id
JOIN course_instance ci ON ci.id = pa.course_instance_id
GROUP BY ci.academic_period_id, al.employee_id;
CREATE UNIQUE INDEX ix_mv_teacher_period ON mv_teacher_period_load (academic_period_id, employee_id);

-- PostgreSQL does not use a B-tree index for a low-selectivity boolean test.
-- This illustrative index is intentionally retained for the EXPLAIN comparison.
CREATE INDEX ix_allocation_hours_boolean ON teaching_allocation ((allocation_hours > 0));

-- After inserting a new teaching_allocation row, compare this stale result with
-- base-table totals; refresh and record the elapsed wall-clock time.
REFRESH MATERIALIZED VIEW CONCURRENTLY mv_allocated_instance_hours;

-- Mismatch report using pre-aggregated one-row-per-instance inputs.
SELECT c.course_code, ci.instance_id, p.planned_hours, a.allocated_hours,
       round(100 * abs(coalesce(a.allocated_hours, 0) - p.planned_hours)
             / nullif(p.planned_hours, 0), 2) AS difference_percent
FROM mv_planned_instance_hours p
JOIN course_instance ci ON ci.id = p.course_instance_id
JOIN course_layout cl ON cl.id = ci.course_layout_id
JOIN course c ON c.id = cl.course_id
LEFT JOIN mv_allocated_instance_hours a ON a.course_instance_id = p.course_instance_id
WHERE abs(coalesce(a.allocated_hours, 0) - p.planned_hours) > 0.15 * p.planned_hours;

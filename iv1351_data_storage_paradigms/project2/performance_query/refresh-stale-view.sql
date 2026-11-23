-- Shows that a materialized view goes out of date after a new allocation, then refreshes it
-- and measures how long the refresh takes. This is the fourth point of the "make it fast"
-- requirement, and it is the only script here that is about write cost rather than read speed.
--
-- Run it manually, against candidate D:
--     sudo -u postgres psql -d course_database -f refresh-stale-view.sql
--
-- Part one is the demonstration, and runs in one transaction that is rolled back, so the data
-- and the views are unchanged afterwards. Part two refreshes each of the three views on its
-- own, both plain and CONCURRENTLY, to measure the cost of keeping them up to date. Part two
-- does write, in the sense that it recomputes the views, and takes about 70 seconds.

\timing on

BEGIN;

-- A teacher with one course instance in 2026 P2, and a planned activity of another
-- course instance in the same period, so that the trigger accepts the allocation
CREATE TEMPORARY TABLE new_allocation ON COMMIT DROP AS
SELECT
    teacher.employee_id,
    teacher.employment_id,
    (
        SELECT planned_activity.id
        FROM planned_activity
        INNER JOIN course_instance ON course_instance.id = planned_activity.course_instance_id
        INNER JOIN academic_period ON academic_period.id = course_instance.academic_period_id
        INNER JOIN period ON period.id = academic_period.period_id
        INNER JOIN teaching_activity ON teaching_activity.id = planned_activity.teaching_activity_id
        WHERE academic_period.academic_year = 2026
          AND period.period_name = 'P2'
          AND teaching_activity.activity_name = 'Lecture'
          AND NOT EXISTS (
              SELECT 1
              FROM teaching_allocation
              INNER JOIN planned_activity AS allocated_activity
                  ON allocated_activity.id = teaching_allocation.planned_activity_id
              WHERE teaching_allocation.employee_id = teacher.employee_id
                AND allocated_activity.course_instance_id = planned_activity.course_instance_id
          )
        ORDER BY planned_activity.id
        LIMIT 1
    ) AS planned_activity_id
FROM teacher_period_load_view AS teacher
WHERE teacher.academic_year = 2026
  AND teacher.period_number = 'P2'
  AND teacher.number_of_courses = 1
ORDER BY teacher.employment_id
LIMIT 1;

\echo '=== before the insert: view and base tables agree'
SELECT number_of_courses, total_hours
FROM teacher_period_load_view
WHERE employee_id = (SELECT employee_id FROM new_allocation)
  AND academic_year = 2026 AND period_number = 'P2';

INSERT INTO teaching_allocation (planned_activity_id, employee_id, allocation_hours)
SELECT planned_activity_id, employee_id, 10 FROM new_allocation;

\echo '=== after the insert: the base tables have 2 course instances, the view still shows 1'
SELECT COUNT(DISTINCT course_instance.id) AS number_of_courses_base_tables
FROM teaching_allocation
INNER JOIN planned_activity ON planned_activity.id = teaching_allocation.planned_activity_id
INNER JOIN course_instance ON course_instance.id = planned_activity.course_instance_id
INNER JOIN academic_period ON academic_period.id = course_instance.academic_period_id
INNER JOIN period ON period.id = academic_period.period_id
WHERE teaching_allocation.employee_id = (SELECT employee_id FROM new_allocation)
  AND academic_period.academic_year = 2026 AND period.period_name = 'P2';

SELECT number_of_courses AS number_of_courses_view, total_hours
FROM teacher_period_load_view
WHERE employee_id = (SELECT employee_id FROM new_allocation)
  AND academic_year = 2026 AND period_number = 'P2';

\echo '=== refresh'
REFRESH MATERIALIZED VIEW teacher_period_load_view;

\echo '=== after the refresh: the view is up to date'
SELECT number_of_courses AS number_of_courses_view, total_hours
FROM teacher_period_load_view
WHERE employee_id = (SELECT employee_id FROM new_allocation)
  AND academic_year = 2026 AND period_number = 'P2';

ROLLBACK;

\echo '=== refresh of each view on its own (outside the demonstration)'
REFRESH MATERIALIZED VIEW teacher_period_load_view;
REFRESH MATERIALIZED VIEW CONCURRENTLY teacher_period_load_view;
REFRESH MATERIALIZED VIEW course_instance_planned_view;
REFRESH MATERIALIZED VIEW CONCURRENTLY course_instance_planned_view;
REFRESH MATERIALIZED VIEW course_instance_mismatch_view;
REFRESH MATERIALIZED VIEW CONCURRENTLY course_instance_mismatch_view;

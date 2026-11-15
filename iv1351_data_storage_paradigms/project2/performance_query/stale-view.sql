-- Shows that teacher_period_load_view is out of date after a new allocation, and times the refresh.
-- Everything runs in one transaction that is rolled back, so the data and the view are unchanged afterwards.

\timing on

BEGIN;

-- A teacher with one course instance in 2026 P2, and a planned activity of another
-- course instance in the same period, so that the trigger accepts the allocation
CREATE TEMPORARY TABLE new_allocation ON COMMIT DROP AS
SELECT
    teacher.employee_id,
    teacher.employment_id,
    (
        SELECT course_activity_view.planned_activity_id
        FROM course_activity_view
        WHERE course_activity_view.academic_year = 2026
          AND course_activity_view.period_number = 'P2'
          AND course_activity_view.activity_name = 'Lecture'
          AND NOT EXISTS (
              SELECT 1
              FROM teaching_allocation
              INNER JOIN planned_activity ON planned_activity.id = teaching_allocation.planned_activity_id
              WHERE teaching_allocation.employee_id = teacher.employee_id
                AND planned_activity.course_instance_id = course_activity_view.course_instance_id
          )
        ORDER BY course_activity_view.planned_activity_id
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
REFRESH MATERIALIZED VIEW course_activity_view;
REFRESH MATERIALIZED VIEW CONCURRENTLY course_activity_view;

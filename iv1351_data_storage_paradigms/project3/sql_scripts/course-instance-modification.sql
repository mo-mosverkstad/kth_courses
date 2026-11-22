BEGIN;

SELECT
    course_instance.num_students
FROM course_instance
WHERE course_instance.instance_id = '2026-50000011'
FOR NO KEY UPDATE;

SELECT
    COALESCE(SUM(planned_activity.planned_hours
                 * teaching_activity.multiplication_factor), 0) AS total_planned_hours
FROM course_instance
INNER JOIN planned_activity
ON course_instance.id = planned_activity.course_instance_id
INNER JOIN teaching_activity
ON teaching_activity.id = planned_activity.teaching_activity_id
WHERE course_instance.instance_id = '2026-50000011';

UPDATE course_instance
SET num_students = num_students + 100
WHERE instance_id = '2026-50000011';

SELECT
    course_instance.num_students
FROM course_instance
WHERE course_instance.instance_id = '2026-50000011';

SELECT
    COALESCE(SUM(planned_activity.planned_hours
                 * teaching_activity.multiplication_factor), 0) AS total_planned_hours
FROM course_instance
INNER JOIN planned_activity
ON course_instance.id = planned_activity.course_instance_id
INNER JOIN teaching_activity
ON teaching_activity.id = planned_activity.teaching_activity_id
WHERE course_instance.instance_id = '2026-50000011';

ROLLBACK;

BEGIN;

DELETE FROM planned_activity AS pa
USING teaching_activity AS ta, course_instance AS ci
WHERE pa.teaching_activity_id = ta.id
  AND pa.course_instance_id = ci.id
  AND ci.instance_id = '2026-50000011'
  AND ta.activity_name = 'Exercise'
RETURNING pa.id, pa.planned_hours;

-- Deletes the Exercise type only if no planned activities still use it.
DELETE FROM teaching_activity AS ta
WHERE ta.activity_name = 'Exercise'
  AND NOT EXISTS (
      SELECT 1
      FROM planned_activity AS pa
      WHERE pa.teaching_activity_id = ta.id
  )
RETURNING ta.id, ta.activity_name;

COMMIT;
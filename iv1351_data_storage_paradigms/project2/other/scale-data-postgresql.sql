-- Run after the Project 1 scripts. Adds one million course instances for the
-- higher-grade performance experiments. Existing teaching activities and
-- course layouts are reused; each generated instance has a lecture plan.
INSERT INTO academic_period (academic_year, period_id, start_date, end_date)
SELECT 2026, p.id,
       make_date(2026, CASE p.period_name WHEN 'P1' THEN 1 WHEN 'P2' THEN 4
                       WHEN 'P3' THEN 7 ELSE 10 END, 1),
       (make_date(2026, CASE p.period_name WHEN 'P1' THEN 1 WHEN 'P2' THEN 4
                       WHEN 'P3' THEN 7 ELSE 10 END, 1)
         + interval '3 months' - interval '1 day')::date
FROM period p
WHERE NOT EXISTS (
    SELECT 1 FROM academic_period ap
    WHERE ap.academic_year = 2026 AND ap.period_id = p.id
);

INSERT INTO course_instance (instance_id, course_layout_id, academic_period_id, num_students)
SELECT '2026-task2-' || p.period_name, cl.id, ap.id, 60
FROM period p
JOIN academic_period ap ON ap.academic_year = 2026 AND ap.period_id = p.id
JOIN course c ON c.course_code = CASE p.period_name
    WHEN 'P1' THEN 'IV1351' WHEN 'P2' THEN 'IX1500'
    WHEN 'P3' THEN 'SF1697' ELSE 'ID1018' END
JOIN course_layout cl ON cl.course_id = c.id AND cl.version = 1;

INSERT INTO planned_activity (planned_hours, teaching_activity_id, course_instance_id)
SELECT 20, ta.id, ci.id
FROM course_instance ci
JOIN academic_period ap ON ap.id = ci.academic_period_id AND ap.academic_year = 2026
JOIN teaching_activity ta ON ta.activity_name = 'Lecture'
WHERE ci.instance_id LIKE '2026-task2-%';

INSERT INTO academic_period (academic_year, period_id, start_date, end_date)
SELECT 2027 + ((g - 1) / 4)::int,
       p.id,
       make_date(2027 + ((g - 1) / 4)::int, 1 + (((g - 1) % 4) * 3), 1),
       (make_date(2027 + ((g - 1) / 4)::int, 1 + (((g - 1) % 4) * 3), 1)
         + interval '3 months' - interval '1 day')::date
FROM generate_series(1, 1000000) AS g
JOIN period p ON p.period_name = 'P' || (1 + ((g - 1) % 4));

INSERT INTO course_instance (instance_id, course_layout_id, academic_period_id, num_students)
SELECT 'scale-' || ap.academic_year || '-' || p.period_name,
       cl.id,
       ap.id,
       30 + (ap.id % 71)::int
FROM academic_period ap
JOIN period p ON p.id = ap.period_id
CROSS JOIN LATERAL (
    SELECT id FROM course_layout ORDER BY id LIMIT 1
) cl
WHERE ap.academic_year >= 2027;

INSERT INTO planned_activity (planned_hours, teaching_activity_id, course_instance_id)
SELECT 20, ta.id, ci.id
FROM course_instance ci
JOIN academic_period ap ON ap.id = ci.academic_period_id
JOIN teaching_activity ta ON ta.activity_name = 'Lecture'
WHERE ap.academic_year >= 2027;

ANALYZE;

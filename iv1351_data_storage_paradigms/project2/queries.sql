-- Run after the Project 1 create, trigger and insertion scripts.
-- PostgreSQL; current year and period are read from the database clock.

-- 1. Planned workload by course instance and activity, including derived activities.
WITH activity_hours AS (
    SELECT ci.id AS course_instance_id,
           c.course_code,
           ci.instance_id,
           ap.academic_year,
           p.period_name,
           ta.activity_name,
           ta.multiplication_factor,
           CASE WHEN daf.id IS NULL THEN pa.planned_hours::numeric
                ELSE round(daf.base_hours
                         + daf.hours_per_student * ci.num_students
                         + daf.hours_per_hp * cl.hp)
           END AS raw_hours
    FROM course_instance ci
    JOIN course_layout cl ON cl.id = ci.course_layout_id
    JOIN course c ON c.id = cl.course_id
    JOIN academic_period ap ON ap.id = ci.academic_period_id
    JOIN period p ON p.id = ap.period_id
    JOIN planned_activity pa ON pa.course_instance_id = ci.id
    JOIN teaching_activity ta ON ta.id = pa.teaching_activity_id
    LEFT JOIN derived_activity_formula daf ON daf.teaching_activity_id = ta.id
    WHERE ap.academic_year = extract(year FROM current_date)::int
)
SELECT course_code, instance_id, academic_year, period_name,
       activity_name, raw_hours,
       round(raw_hours * multiplication_factor, 2) AS workload_hours,
       round(sum(raw_hours * multiplication_factor) OVER
             (PARTITION BY course_instance_id), 2) AS total_workload_hours
FROM activity_hours
ORDER BY course_code, instance_id, activity_name;

-- 2. Actual allocation workload, broken down by teacher and activity.
WITH allocation_hours AS (
    SELECT ci.id AS course_instance_id, c.course_code, ci.instance_id,
           ap.academic_year, p.period_name, e.employment_id,
           pe.first_name || ' ' || pe.last_name AS teacher_name,
           ta.activity_name, ta.multiplication_factor,
           sum(al.allocation_hours)::numeric AS raw_hours
    FROM teaching_allocation al
    JOIN planned_activity pa ON pa.id = al.planned_activity_id
    JOIN course_instance ci ON ci.id = pa.course_instance_id
    JOIN course_layout cl ON cl.id = ci.course_layout_id
    JOIN course c ON c.id = cl.course_id
    JOIN academic_period ap ON ap.id = ci.academic_period_id
    JOIN period p ON p.id = ap.period_id
    JOIN teaching_activity ta ON ta.id = pa.teaching_activity_id
    JOIN employee e ON e.id = al.employee_id
    JOIN person pe ON pe.id = e.person_id
    WHERE ap.academic_year = extract(year FROM current_date)::int
    GROUP BY ci.id, c.course_code, ci.instance_id, ap.academic_year,
             p.period_name, e.employment_id, pe.first_name, pe.last_name,
             ta.activity_name, ta.multiplication_factor
)
SELECT *, round(raw_hours * multiplication_factor, 2) AS workload_hours,
       round(sum(raw_hours * multiplication_factor) OVER
             (PARTITION BY course_instance_id), 2) AS course_total_workload_hours
FROM allocation_hours
ORDER BY course_code, instance_id, employment_id, activity_name;

-- 3. Teacher totals for all current-year course instances.
SELECT e.employment_id, pe.first_name || ' ' || pe.last_name AS teacher_name,
       round(sum(al.allocation_hours * ta.multiplication_factor), 2) AS workload_hours
FROM teaching_allocation al
JOIN planned_activity pa ON pa.id = al.planned_activity_id
JOIN teaching_activity ta ON ta.id = pa.teaching_activity_id
JOIN course_instance ci ON ci.id = pa.course_instance_id
JOIN academic_period ap ON ap.id = ci.academic_period_id
JOIN employee e ON e.id = al.employee_id
JOIN person pe ON pe.id = e.person_id
WHERE ap.academic_year = extract(year FROM current_date)::int
GROUP BY e.employment_id, pe.first_name, pe.last_name
ORDER BY e.employment_id;

-- 4. Employees with more than :course_instance_limit distinct instances in the current period.
-- Set the psql variable, e.g. \set course_instance_limit 3
SELECT e.employment_id, pe.first_name || ' ' || pe.last_name AS teacher_name,
       count(DISTINCT ci.id) AS course_instances
FROM teaching_allocation al
JOIN planned_activity pa ON pa.id = al.planned_activity_id
JOIN course_instance ci ON ci.id = pa.course_instance_id
JOIN academic_period ap ON ap.id = ci.academic_period_id
JOIN employee e ON e.id = al.employee_id
JOIN person pe ON pe.id = e.person_id
WHERE ap.start_date <= current_date AND current_date < ap.end_date
GROUP BY e.employment_id, pe.first_name, pe.last_name
HAVING count(DISTINCT ci.id) > :course_instance_limit
ORDER BY course_instances DESC, e.employment_id;

-- Higher grade: correct mismatch calculation. Only activities present in planning
-- contribute; planned-only and allocated-only activities are both retained.
WITH planned AS (
    SELECT pa.course_instance_id,
           sum((CASE WHEN daf.id IS NULL THEN pa.planned_hours::numeric
                     ELSE round(daf.base_hours + daf.hours_per_student * ci.num_students
                              + daf.hours_per_hp * cl.hp) END)
               * ta.multiplication_factor) AS hours
    FROM planned_activity pa
    JOIN course_instance ci ON ci.id = pa.course_instance_id
    JOIN course_layout cl ON cl.id = ci.course_layout_id
    JOIN teaching_activity ta ON ta.id = pa.teaching_activity_id
    LEFT JOIN derived_activity_formula daf ON daf.teaching_activity_id = ta.id
    GROUP BY pa.course_instance_id
), allocated AS (
    SELECT pa.course_instance_id,
           sum(al.allocation_hours * ta.multiplication_factor) AS hours
    FROM teaching_allocation al
    JOIN planned_activity pa ON pa.id = al.planned_activity_id
    JOIN teaching_activity ta ON ta.id = pa.teaching_activity_id
    GROUP BY pa.course_instance_id
)
SELECT c.course_code, ci.instance_id, coalesce(p.hours, 0) AS planned_hours,
       coalesce(a.hours, 0) AS allocated_hours,
       round(100 * abs(coalesce(a.hours, 0) - coalesce(p.hours, 0))
             / nullif(p.hours, 0), 2) AS difference_percent
FROM course_instance ci
JOIN course_layout cl ON cl.id = ci.course_layout_id
JOIN course c ON c.id = cl.course_id
JOIN academic_period ap ON ap.id = ci.academic_period_id
LEFT JOIN planned p ON p.course_instance_id = ci.id
LEFT JOIN allocated a ON a.course_instance_id = ci.id
WHERE ap.academic_year = extract(year FROM current_date)::int
  AND abs(coalesce(a.hours, 0) - coalesce(p.hours, 0)) > 0.15 * coalesce(p.hours, 0)
ORDER BY difference_percent DESC;

-- Intentionally wrong: joins raw activity rows before summing, multiplying each
-- planned activity by the number of allocations attached to it.
SELECT ci.instance_id, sum(pa.planned_hours * ta.multiplication_factor) AS wrong_planned_hours,
       sum(al.allocation_hours * ta.multiplication_factor) AS allocated_hours
FROM course_instance ci
JOIN planned_activity pa ON pa.course_instance_id = ci.id
JOIN teaching_activity ta ON ta.id = pa.teaching_activity_id
LEFT JOIN teaching_allocation al ON al.planned_activity_id = pa.id
GROUP BY ci.instance_id;

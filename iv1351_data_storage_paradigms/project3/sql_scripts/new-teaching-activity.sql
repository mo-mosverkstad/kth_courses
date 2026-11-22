-- Fname: Mallory, Lname: Terrell -> 500018

BEGIN;

INSERT INTO teaching_activity (activity_name, multiplication_factor) VALUES
('Exercise', 2.00);

INSERT INTO planned_activity (planned_hours, teaching_activity_id, course_instance_id) VALUES
(
    30,
    (SELECT teaching_activity.id FROM teaching_activity
     WHERE teaching_activity.activity_name = 'Exercise'),
    (SELECT course_instance.id FROM course_instance
     WHERE course_instance.instance_id = '2026-50000011')
);

INSERT INTO teaching_allocation (planned_activity_id, employee_id, allocation_hours) VALUES
(
    (SELECT planned_activity.id
     FROM course_instance
     INNER JOIN planned_activity
     ON course_instance.id = planned_activity.course_instance_id
     INNER JOIN teaching_activity
     ON teaching_activity.id = planned_activity.teaching_activity_id
     WHERE course_instance.instance_id = '2026-50000011'
         AND teaching_activity.activity_name = 'Exercise'),
    (SELECT employee.id FROM employee WHERE employee.employment_id = 500018),
    15
);

SELECT
    course.course_code,
    course_instance.instance_id,
    course_layout.version,
    academic_period.academic_year,
    period.period_name,
    teaching_activity.activity_name,
    teaching_activity.multiplication_factor,
    planned_activity.planned_hours,
    employee.employment_id,
    person.first_name,
    person.last_name,
    teaching_allocation.allocation_hours
FROM teaching_allocation
INNER JOIN planned_activity
ON planned_activity.id = teaching_allocation.planned_activity_id
INNER JOIN teaching_activity
ON teaching_activity.id = planned_activity.teaching_activity_id
INNER JOIN course_instance
ON course_instance.id = planned_activity.course_instance_id
INNER JOIN course_layout
ON course_layout.id = course_instance.course_layout_id
INNER JOIN course
ON course.id = course_layout.course_id
INNER JOIN academic_period
ON academic_period.id = course_instance.academic_period_id
INNER JOIN period
ON period.id = academic_period.period_id
INNER JOIN employee
ON employee.id = teaching_allocation.employee_id
INNER JOIN person
ON person.id = employee.person_id
WHERE teaching_activity.activity_name = 'Exercise';

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

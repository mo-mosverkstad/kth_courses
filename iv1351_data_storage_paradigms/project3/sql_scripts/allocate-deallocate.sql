-- Fname: Mallory, Lname: Terrell -> 500018
-- Employee 500001 already has 4 course instances in the period of 2023-50000151

\set ON_ERROR_STOP off

BEGIN;

-- Retrieve the employment id for Mallory Terrell
SELECT
    employee.employment_id
FROM person
INNER JOIN employee
ON person.id = employee.person_id
WHERE person.first_name='Mallory' AND person.last_name='Terrell';

-- Retrieve the id of the employment id 500018
SELECT
    employee.id
FROM employee
WHERE employee.employment_id = 500018
FOR NO KEY UPDATE;

-- Retrieve the number of course instance Mallory has (employment id=500018)
SELECT
    COUNT(DISTINCT course_instance.id) AS allocated_course_instances
FROM teaching_allocation
INNER JOIN planned_activity
ON planned_activity.id = teaching_allocation.planned_activity_id
INNER JOIN course_instance
ON course_instance.id = planned_activity.course_instance_id
WHERE teaching_allocation.employee_id =
    (SELECT employee.id FROM employee WHERE employee.employment_id = 500018)
    AND course_instance.academic_period_id =
    (SELECT course_instance.academic_period_id FROM course_instance
     WHERE course_instance.instance_id = '2026-50000011');

-- Allocate Mallory into teaching allocation
INSERT INTO teaching_allocation (planned_activity_id, employee_id, allocation_hours) VALUES
(
    (SELECT planned_activity.id
     FROM course_instance
     INNER JOIN planned_activity
     ON course_instance.id = planned_activity.course_instance_id
     INNER JOIN teaching_activity
     ON teaching_activity.id = planned_activity.teaching_activity_id
     WHERE course_instance.instance_id = '2026-50000011'
         AND teaching_activity.activity_name = 'Administration'),
    (SELECT employee.id FROM employee WHERE employee.employment_id = 500018),
    30
);

-- Retrieve back test
SELECT
    course_instance.instance_id,
    teaching_activity.activity_name,
    employee.employment_id,
    teaching_allocation.allocation_hours
FROM teaching_allocation
INNER JOIN planned_activity
ON planned_activity.id = teaching_allocation.planned_activity_id
INNER JOIN teaching_activity
ON teaching_activity.id = planned_activity.teaching_activity_id
INNER JOIN course_instance
ON course_instance.id = planned_activity.course_instance_id
INNER JOIN employee
ON employee.id = teaching_allocation.employee_id
WHERE course_instance.instance_id = '2026-50000011'
    AND teaching_activity.activity_name = 'Administration'
    AND employee.employment_id = 500018;

-- Deallocate Mallory from teaching allocation
DELETE FROM teaching_allocation
WHERE teaching_allocation.planned_activity_id =
    (SELECT planned_activity.id
     FROM course_instance
     INNER JOIN planned_activity
     ON course_instance.id = planned_activity.course_instance_id
     INNER JOIN teaching_activity
     ON teaching_activity.id = planned_activity.teaching_activity_id
     WHERE course_instance.instance_id = '2026-50000011'
         AND teaching_activity.activity_name = 'Administration')
    AND teaching_allocation.employee_id =
    (SELECT employee.id FROM employee WHERE employee.employment_id = 500018);

SAVEPOINT over_the_limit;

-- Expected to fail case
INSERT INTO teaching_allocation (planned_activity_id, employee_id, allocation_hours) VALUES
(
    (SELECT planned_activity.id
     FROM course_instance
     INNER JOIN planned_activity
     ON course_instance.id = planned_activity.course_instance_id
     INNER JOIN teaching_activity
     ON teaching_activity.id = planned_activity.teaching_activity_id
     WHERE course_instance.instance_id = '2023-50000151'
         AND teaching_activity.activity_name = 'Lecture'),
    (SELECT employee.id FROM employee WHERE employee.employment_id = 500001),
    30
);

ROLLBACK TO SAVEPOINT over_the_limit;

ROLLBACK;

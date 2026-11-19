-- Shows what the triggers do, by printing the planned activities after each change.
-- Statements that must be rejected are wrapped in a savepoint, so that the script
-- can continue after the expected error. Nothing is kept, the script ends with ROLLBACK.

\set ON_ERROR_STOP off

BEGIN;

INSERT INTO course (course_code, course_name)
VALUES
    ('IK1203', 'Network and Communication');

INSERT INTO course_layout (min_students, max_students, hp, version, course_id)
VALUES
    (78, 130, 7.5, 1, (SELECT id FROM course WHERE course_code = 'IK1203')),
    (78, 130, 15.0, 2, (SELECT id FROM course WHERE course_code = 'IK1203')),
    (78, 130, 7.5, 3, (SELECT id FROM course WHERE course_code = 'IK1203')),
    (78, 130, 7.5, 4, (SELECT id FROM course WHERE course_code = 'IK1203')),
    (78, 130, 7.5, 5, (SELECT id FROM course WHERE course_code = 'IK1203')),
    (78, 130, 7.5, 6, (SELECT id FROM course WHERE course_code = 'IK1203'));

INSERT INTO academic_period (academic_year, period_id, start_date, end_date)
VALUES
    (
        2027,
        (SELECT id FROM period WHERE period_name = 'P3'),
        '2027-07-01',
        '2027-09-30'
    );

CREATE TEMP VIEW test_planned_activity AS
SELECT
    course_instance.instance_id,
    course_layout.version,
    course_layout.hp,
    course_instance.num_students,
    teaching_activity.activity_name,
    planned_activity.planned_hours
FROM course
INNER JOIN course_layout ON course_layout.course_id = course.id
INNER JOIN course_instance ON course_instance.course_layout_id = course_layout.id
INNER JOIN planned_activity ON planned_activity.course_instance_id = course_instance.id
INNER JOIN teaching_activity ON teaching_activity.id = planned_activity.teaching_activity_id
WHERE course.course_code = 'IK1203' AND course_instance.instance_id = '2027-32288'
ORDER BY teaching_activity.activity_name;

CREATE TEMP VIEW test_allocated_instance AS
SELECT
    employee.employment_id,
    COUNT(DISTINCT course_instance.id) AS allocated_course_instances
FROM employee
INNER JOIN teaching_allocation ON teaching_allocation.employee_id = employee.id
INNER JOIN planned_activity ON planned_activity.id = teaching_allocation.planned_activity_id
INNER JOIN course_instance ON course_instance.id = planned_activity.course_instance_id
INNER JOIN academic_period ON academic_period.id = course_instance.academic_period_id
WHERE academic_period.academic_year = 2027
GROUP BY employee.employment_id;

\echo
\echo '1. A new course instance with 121 students is inserted. Examination and administration must appear by default (32 + 0.725 * 121 = 120 hours, 28 + 0.2 * 121 + 2 * 7.5 = 67 hours)'

INSERT INTO course_instance (instance_id, course_layout_id, academic_period_id, num_students)
VALUES
    (
        '2027-32288',
        (
            SELECT course_layout.id
            FROM course_layout
            INNER JOIN course ON course.id = course_layout.course_id
            WHERE course.course_code = 'IK1203' AND course_layout.version = 1
        ),
        (
            SELECT academic_period.id
            FROM academic_period
            INNER JOIN period ON period.id = academic_period.period_id
            WHERE period.period_name = 'P3' AND academic_period.academic_year = 2027
        ),
        121
    );

SELECT * FROM test_planned_activity;

\echo
\echo '2. The number of students is changed to 200. (32 + 0.725 * 200 = 177 hours, 28 + 0.2 * 200 + 2 * 7.5 = 83 hours)'

UPDATE course_instance
SET num_students = 200
WHERE instance_id = '2027-32288';

SELECT * FROM test_planned_activity;

\echo
\echo '3. The course layout is changed to 30 credits. Administration: 28 + 0.2 * 200 + 2 * 30 = 128 hours'

UPDATE course_layout
SET hp = 30.0
WHERE course_id = (SELECT id FROM course WHERE course_code = 'IK1203')
  AND version = 1;

SELECT * FROM test_planned_activity;

\echo
\echo '4. The course instance is moved to course layout version 2, which has 15 credits, Administration: 28 + 0.2 * 200 + 2 * 15 = 98 hours'

UPDATE course_instance
SET course_layout_id = (
    SELECT course_layout.id
    FROM course_layout
    INNER JOIN course ON course.id = course_layout.course_id
    WHERE course.course_code = 'IK1203' AND course_layout.version = 2
)
WHERE instance_id = '2027-32288';

SELECT * FROM test_planned_activity;

\echo
\echo '5. The base hours of the examination formula are changed from 32 to 100, changes are undone (Examination: 100 + 0.725 * 200 = 245 hours)'

SAVEPOINT changed_formula;

UPDATE derived_activity_formula
SET base_hours = 100
WHERE teaching_activity_id = (SELECT id FROM teaching_activity WHERE activity_name = 'Examination');

SELECT * FROM test_planned_activity;

ROLLBACK TO SAVEPOINT changed_formula;

\echo
\echo '6. Add lecture of 60 hours in IK1203'

INSERT INTO planned_activity (planned_hours, teaching_activity_id, course_instance_id)
VALUES
    (
        60,
        (SELECT id FROM teaching_activity WHERE activity_name = 'Lecture'),
        (SELECT id FROM course_instance WHERE instance_id = '2027-32288')
    );

SELECT * FROM test_planned_activity;

\echo
\echo '7. The planned hours of examination are changed by hand. Must reject!!!'

SAVEPOINT rejected;

UPDATE planned_activity
SET planned_hours = 1
WHERE course_instance_id = (SELECT id FROM course_instance WHERE instance_id = '2027-32288')
  AND teaching_activity_id = (SELECT id FROM teaching_activity WHERE activity_name = 'Examination');

ROLLBACK TO SAVEPOINT rejected;

\echo
\echo '8. Administration is deleted by hand. Must rejected!!!'

SAVEPOINT rejected;

DELETE FROM planned_activity
WHERE course_instance_id = (SELECT id FROM course_instance WHERE instance_id = '2027-32288')
  AND teaching_activity_id = (SELECT id FROM teaching_activity WHERE activity_name = 'Administration');

ROLLBACK TO SAVEPOINT rejected;

\echo
\echo '9. Another examination activity is inserted by hand. Must rejected!!!'

SAVEPOINT rejected;

INSERT INTO planned_activity (planned_hours, teaching_activity_id, course_instance_id)
VALUES
    (
        10,
        (SELECT id FROM teaching_activity WHERE activity_name = 'Examination'),
        (SELECT id FROM course_instance WHERE instance_id = '2027-32288')
    );

ROLLBACK TO SAVEPOINT rejected;

\echo
\echo '10. The examination formula is deleted. Triggers cannot calculate the planned hours without it. Must reject!!!'

SAVEPOINT rejected;

DELETE FROM derived_activity_formula
WHERE teaching_activity_id = (SELECT id FROM teaching_activity WHERE activity_name = 'Examination');

ROLLBACK TO SAVEPOINT rejected;

\echo
\echo '11. The examination activity is renamed. Triggers does not recognise the derived activities by their names. Must reject!!!'

SAVEPOINT rejected;

UPDATE teaching_activity
SET activity_name = 'Exam'
WHERE activity_name = 'Examination';

ROLLBACK TO SAVEPOINT rejected;

\echo
\echo '12. Check nothing above change the data, The planned hours must still be the same as in step 6, lecture must still be possible to update'

UPDATE planned_activity
SET planned_hours = 70
WHERE course_instance_id = (SELECT id FROM course_instance WHERE instance_id = '2027-32288')
  AND teaching_activity_id = (SELECT id FROM teaching_activity WHERE activity_name = 'Lecture');

SELECT * FROM test_planned_activity;

\echo
\echo '13. One teacher is allocated to the examination of 5 course instances in the same academic period. The 1st 4 must be accepted and the 5th rejected!!!'

INSERT INTO course_instance (instance_id, course_layout_id, academic_period_id, num_students)
SELECT
    '2027-3228' || course_layout.version,
    course_layout.id,
    academic_period.id,
    100
FROM course_layout
INNER JOIN course ON course.id = course_layout.course_id
INNER JOIN academic_period ON academic_period.academic_year = 2027
WHERE course.course_code = 'IK1203' AND course_layout.version IN (3, 4, 5, 6);

INSERT INTO teaching_allocation (planned_activity_id, employee_id, allocation_hours)
SELECT
    planned_activity.id,
    (SELECT id FROM employee ORDER BY id LIMIT 1),
    10
FROM planned_activity
INNER JOIN teaching_activity ON teaching_activity.id = planned_activity.teaching_activity_id
INNER JOIN course_instance ON course_instance.id = planned_activity.course_instance_id
INNER JOIN academic_period ON academic_period.id = course_instance.academic_period_id
WHERE teaching_activity.activity_name = 'Examination'
  AND academic_period.academic_year = 2027
  AND course_instance.instance_id IN ('2027-32288', '2027-32283', '2027-32284', '2027-32285');

SELECT * FROM test_allocated_instance;

\echo
\echo 'The fifth course instance must now be rejected!!!'

SAVEPOINT rejected;

INSERT INTO teaching_allocation (planned_activity_id, employee_id, allocation_hours)
SELECT
    planned_activity.id,
    (SELECT id FROM employee ORDER BY id LIMIT 1),
    10
FROM planned_activity
INNER JOIN teaching_activity ON teaching_activity.id = planned_activity.teaching_activity_id
INNER JOIN course_instance ON course_instance.id = planned_activity.course_instance_id
WHERE teaching_activity.activity_name = 'Examination'
  AND course_instance.instance_id = '2027-32286';

ROLLBACK TO SAVEPOINT rejected;

SELECT * FROM test_allocated_instance;

ROLLBACK;

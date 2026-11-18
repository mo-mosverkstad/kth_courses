BEGIN;

INSERT INTO course (course_code, course_name)
VALUES
    ('IK1203', 'Network and Communication');

INSERT INTO course_layout (min_students, max_students, hp, version, course_id)
VALUES
    (78, 130, 7.5, 1, (SELECT id FROM course WHERE course_code = 'IK1203'));

INSERT INTO course_instance (instance_id, course_layout_id, academic_period_id, num_students)
VALUES
    (
        '2026-32288',
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
            WHERE period.period_name = 'P3' AND academic_period.academic_year = 2026
        ),
        121
    );

SELECT
    academic_period.academic_year,
    period.period_name,
    course.course_code,
    course.course_name,
    course_layout.version,
    teaching_activity.activity_name,
    planned_activity.planned_hours
FROM course
INNER JOIN course_layout ON course_layout.course_id = course.id
INNER JOIN course_instance ON course_instance.course_layout_id = course_layout.id
INNER JOIN academic_period ON academic_period.id = course_instance.academic_period_id
INNER JOIN period ON period.id = academic_period.period_id
INNER JOIN planned_activity ON planned_activity.course_instance_id = course_instance.id
INNER JOIN teaching_activity ON teaching_activity.id = planned_activity.teaching_activity_id
WHERE course.course_code = 'IK1203'
ORDER BY teaching_activity.activity_name;

ROLLBACK;

INSERT INTO course_layout (course_code, course_name)
VALUES
    ('IX1500', 'Discrete Mathematics'),
    ('IV1351', 'Data Storage Paradigms'),
    ('SF1697', 'Algebra and Geometry'),
    ('SF1696', 'Calculus in One Variable'),
    ('SF1695', 'Basic course in Mathematics'),
    ('IX1501', 'Mathematical Statistics'),
    ('ID1018', 'Programming I'),
    ('ID1021', 'Algorithms and Data Structures'),
    ('IV1350', 'Object-Oriented Design'),
    ('IS1200', 'Computer Hardware Engineering'),
    ('IS2202', 'Computer Systems Architecture'),
    ('ID2202', 'Compilers and Execution Environments'),
    ('IS1300', 'Embedded Systems'),
    ('IE1204', 'Digital Design'),
    ('IF1330', 'Electrical Engineering'),
    ('IE1202', 'Analog Electronics'),
    ('II1303', 'Signal Processing'),
    ('IL1332', 'Digital System Design Using Hardware Description Languages');
    

INSERT INTO course_layout_version (
    min_students,
    max_students,
    ects_credits,
    version,
    course_layout_id
)
SELECT
    v.min_students,
    v.max_students,
    v.ects_credits,
    1 AS version,
    cl.id
FROM (
    SELECT 'IX1500' AS course_code, 1 AS min_students, 120 AS max_students, 7.5 AS ects_credits
    UNION ALL SELECT 'IV1351', 1, 100, 7.5
    UNION ALL SELECT 'SF1697', 1, 150, 7.5
    UNION ALL SELECT 'SF1696', 1, 150, 7.5
    UNION ALL SELECT 'SF1695', 1, 150, 7.5
    UNION ALL SELECT 'IX1501', 25, 120, 7.5
    UNION ALL SELECT 'ID1018', 1, 100, 7.5
    UNION ALL SELECT 'ID1021', 1, 100, 7.5
    UNION ALL SELECT 'IV1350', 1, 100, 7.5
    UNION ALL SELECT 'IS1200', 1, 100, 7.5
    UNION ALL SELECT 'IS2202', 1, 80, 7.5
    UNION ALL SELECT 'ID2202', 1, 80, 7.5
    UNION ALL SELECT 'IS1300', 1, 80, 7.5
    UNION ALL SELECT 'IE1204', 1, 100, 7.5
    UNION ALL SELECT 'IF1330', 1, 100, 7.5
    UNION ALL SELECT 'IE1202', 1, 100, 7.5
    UNION ALL SELECT 'II1303', 1, 100, 7.5
    UNION ALL SELECT 'IL1332', 1, 80, 7.5
) AS v
INNER JOIN course_layout AS cl
    ON cl.course_code = v.course_code;



INSERT INTO course_instance (
    instance_id,
    num_students,
    study_period,
    study_year,
    course_layout_version_id
)
SELECT
    -- e.g. '2025-50011': year, '-5', 3-digit course id, period number
    CONCAT(v.study_year, '-5', LPAD(CAST(cl.id AS CHAR(3)), 3, '0'), RIGHT(v.study_period, 1)),
    v.num_students,
    v.study_period,
    v.study_year,
    clv.id
FROM (
    SELECT 'IX1500' AS course_code, 110 AS num_students, 'P1' AS study_period, 2025 AS study_year
    UNION ALL SELECT 'IV1351', 90, 'P2', 2025
    UNION ALL SELECT 'SF1697', 120, 'P4', 2025
    UNION ALL SELECT 'SF1696', 120, 'P3', 2025
    UNION ALL SELECT 'SF1695', 120, 'P1', 2025
    UNION ALL SELECT 'IX1501', 75, 'P1', 2025
    UNION ALL SELECT 'ID1018', 110, 'P2', 2025
    UNION ALL SELECT 'ID1021', 110, 'P3', 2025
    UNION ALL SELECT 'IV1350', 100, 'P4', 2025
    UNION ALL SELECT 'IS1200', 100, 'P1', 2025
    UNION ALL SELECT 'IS2202', 80, 'P2', 2025
    UNION ALL SELECT 'ID2202', 80, 'P2', 2025
    UNION ALL SELECT 'IS1300', 80, 'P2', 2025
    UNION ALL SELECT 'IE1204', 110, 'P2', 2025
    UNION ALL SELECT 'IF1330', 80, 'P1', 2025
    UNION ALL SELECT 'IE1202', 80, 'P2', 2025
    UNION ALL SELECT 'II1303', 80, 'P2', 2025
    UNION ALL SELECT 'IL1332', 80, 'P1', 2025
    
    -- Academic year 2024
    UNION ALL SELECT 'IX1500', 105, 'P1', 2024
    UNION ALL SELECT 'IV1351', 85, 'P2', 2024
    UNION ALL SELECT 'SF1697', 115, 'P4', 2024
    UNION ALL SELECT 'SF1696', 115, 'P3', 2024
    UNION ALL SELECT 'SF1695', 110, 'P1', 2024
    UNION ALL SELECT 'IX1501', 70, 'P1', 2024
    UNION ALL SELECT 'ID1018', 105, 'P2', 2024
    UNION ALL SELECT 'ID1021', 105, 'P3', 2024
    UNION ALL SELECT 'IV1350', 95, 'P4', 2024
    UNION ALL SELECT 'IS1200', 95, 'P1', 2024
    UNION ALL SELECT 'IS2202', 75, 'P2', 2024
    UNION ALL SELECT 'ID2202', 75, 'P2', 2024
    UNION ALL SELECT 'IS1300', 75, 'P2', 2024
    UNION ALL SELECT 'IE1204', 105, 'P2', 2024
    UNION ALL SELECT 'IF1330', 75, 'P1', 2024
    UNION ALL SELECT 'IE1202', 75, 'P2', 2024
    UNION ALL SELECT 'II1303', 75, 'P2', 2024
    UNION ALL SELECT 'IL1332', 75, 'P1', 2024

    -- Academic year 2023 (representative subset)
    UNION ALL SELECT 'IX1500', 95, 'P1', 2023
    UNION ALL SELECT 'SF1697', 105, 'P4', 2023
    UNION ALL SELECT 'SF1696', 105, 'P3', 2023
    UNION ALL SELECT 'SF1695', 100, 'P1', 2023
    UNION ALL SELECT 'ID1018', 95, 'P2', 2023
    UNION ALL SELECT 'ID1021', 95, 'P3', 2023
    UNION ALL SELECT 'IV1350', 85, 'P4', 2023
    UNION ALL SELECT 'IS1200', 85, 'P1', 2023

) AS v
INNER JOIN course_layout AS cl
    ON cl.course_code = v.course_code
INNER JOIN course_layout_version AS clv
    ON clv.course_layout_id = cl.id
    AND clv.version = 1;

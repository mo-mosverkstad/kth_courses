INSERT INTO course (course_code, course_name)
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

INSERT INTO course (course_code, course_name)
SELECT CONCAT('AB', LPAD(i::TEXT, 5, '0')), CONCAT('Course AB', LPAD(i::TEXT, 5, '0'))
FROM generate_series(0, 99999) AS i;


INSERT INTO course_layout (
    min_students,
    max_students,
    hp,
    version,
    course_id
)
SELECT
    1,
    CASE
        WHEN course_code LIKE 'SF%' THEN 150
        WHEN course_code LIKE 'IX%' THEN 120
        WHEN course_code LIKE 'IS%' THEN 80
        ELSE 100
    END,
    CASE
        WHEN course_code LIKE 'I_2%' THEN 9.0
        ELSE 7.5
    END,
    1,
    id
FROM course;


INSERT INTO period (period_name)
VALUES ('P1'), ('P2'), ('P3'), ('P4');

INSERT INTO academic_period (
    academic_year,
    period_id,
    start_date,
    end_date
)
SELECT
    academic_year,
    period.id,
    CASE
        WHEN period.period_name = 'P1' THEN MAKE_DATE(academic_year, 01, 01)
        WHEN period.period_name = 'P2' THEN MAKE_DATE(academic_year, 04, 01)
        WHEN period.period_name = 'P3' THEN MAKE_DATE(academic_year, 07, 01)
        WHEN period.period_name = 'P4' THEN MAKE_DATE(academic_year, 10, 01)
    END,
    CASE
        WHEN period.period_name = 'P1' THEN MAKE_DATE(academic_year, 03, 31)
        WHEN period.period_name = 'P2' THEN MAKE_DATE(academic_year, 06, 30)
        WHEN period.period_name = 'P3' THEN MAKE_DATE(academic_year, 09, 30)
        WHEN period.period_name = 'P4' THEN MAKE_DATE(academic_year, 12, 31)
    END
FROM generate_series(2023, 2026) AS academic_year, (
    SELECT id, period_name FROM period
) AS period;

WITH course_data(course_code, base_students, study_period) AS (
    VALUES
        ('IX1500', 110, 'P1'),
        ('IV1351', 90, 'P2'),
        ('SF1697', 120, 'P4'),
        ('SF1696', 120, 'P3'),
        ('SF1695', 120, 'P1'),
        ('IX1501', 75, 'P1'),
        ('ID1018', 110, 'P2'),
        ('ID1021', 110, 'P3'),
        ('IV1350', 100, 'P4'),
        ('IS1200', 100, 'P1'),
        ('IS2202', 80, 'P2'),
        ('ID2202', 80, 'P2'),
        ('IS1300', 80, 'P2'),
        ('IE1204', 110, 'P2'),
        ('IF1330', 80, 'P1'),
        ('IE1202', 80, 'P2'),
        ('II1303', 80, 'P2'),
        ('IL1332', 80, 'P1')
    UNION ALL
    SELECT
        course_code,
        100 AS base_students,
        CASE ROW_NUMBER() OVER (ORDER BY id) % 4
            WHEN 0 THEN 'P1'
            WHEN 1 THEN 'P2'
            WHEN 2 THEN 'P3'
            WHEN 3 THEN 'P4'
        END
    FROM course
    WHERE course_code LIKE 'AB%'
),
years AS (
    SELECT
        year
    FROM generate_series(1970, 2030) AS year
)
INSERT INTO course_instance (
    instance_id,
    course_layout_id,
    academic_period_id,
    num_students
)
SELECT
    CONCAT(
        years.year,
        '-5',
        LPAD(course.id::TEXT, 6, '0'),
        RIGHT(course_data.study_period, 1)
    ),
    course_layout.id,
    academic_period.id,
    course_data.base_students + ROUND(110 + years.year % 23 / 7)
FROM course_data CROSS JOIN years
JOIN course
    ON course.course_code = course_data.course_code
JOIN course_layout
    ON course_layout.course_id = course.id
    AND course_layout.version = 1
JOIN period
    ON period.period_name = course_data.study_period
JOIN academic_period
    ON academic_period.academic_year = years.year
    AND academic_period.period_id = period.id;


INSERT INTO person (personal_number,first_name,last_name)
VALUES
  ('4689185576','Alexander','Faulkner'),
  ('4265395646','Hakeem','Morrison'),
  ('1544659622','Hilda','Crawford'),
  ('3286345052','Abel','Good'),
  ('6680931650','Grant','Lester'),
  ('6259118532','Charles','Gentry'),
  ('8580989374','Tanisha','Davidson'),
  ('1044144913','Odessa','Leonard'),
  ('1191676461','Fitzgerald','Hancock'),
  ('1238682057','Aladdin','Myers');
INSERT INTO person (personal_number,first_name,last_name)
VALUES
  ('6861061717','Gareth','Jefferson'),
  ('6084815807','Robert','Eaton'),
  ('5006765376','Ulla','Glover'),
  ('3469756492','Ashton','Hester'),
  ('7672554955','Curran','Crosby'),
  ('6025829417','Christian','Heath'),
  ('8480022451','Talon','Morales'),
  ('8171942841','Mallory','Terrell'),
  ('2734803456','Cheryl','Bruce'),
  ('6658263404','Mark','Roth');
INSERT INTO person (personal_number,first_name,last_name)
VALUES
  ('5124875468','Althea','Henry'),
  ('1662569802','Brady','Joseph'),
  ('9076157891','Alisa','Richards'),
  ('7747223773','Sylvester','Lambert'),
  ('6471598381','Kamal','Wilcox'),
  ('3184594422','Paki','Frederick'),
  ('7976866637','Stacy','Shaffer'),
  ('8809777193','Kenneth','Carroll'),
  ('3775892422','Damian','Wilkinson'),
  ('4453123313','Colette','Bush');
INSERT INTO person (personal_number,first_name,last_name)
VALUES
  ('3498713432','Yasir','Parker'),
  ('1924525089','Abigail','Gallegos');
INSERT INTO person (personal_number, first_name, last_name)
SELECT
    LPAD(i::TEXT, 10, '0') AS personal_number,
    CONCAT('F', i::TEXT) AS first_name,
    CONCAT('L', i::TEXT) AS last_name
FROM
    generate_series(0, 450000) AS i;


INSERT INTO address (city,zip,street,house_number,country)
VALUES
  ('Åkersberga','41830','1513 Id Rd.','47','Sweden'),
  ('Falun','74961','488-3866 Euismod Ave','9','Sweden'),
  ('Borås','72261','P.O. Box 180, 4262 Sagittis Ave','15','Sweden'),
  ('Jönköping','72347','Ap #441-4202 Nunc Avenue','19','Sweden'),
  ('Vetlanda','21615','P.O. Box 316, 8464 Maecenas Rd.','23','Sweden'),
  ('Tumba','58670','Ap #494-3173 Aliquam St.','28','Sweden'),
  ('Skövde','28101','670-2026 Erat Rd.','39','Sweden'),
  ('Alingsås','73831','420-3135 Cursus Av.','24','Sweden'),
  ('Täby','58434','251-4891 Fringilla St.','34','Sweden'),
  ('Gävle','13222','Ap #211-8599 Inceptos Road','3','Sweden');
INSERT INTO address (city,zip,street,house_number,country)
VALUES
  ('Avesta','04510','Ap #114-6789 Netus St.','36','Sweden'),
  ('Gävle','65685','126-867 Sem, Ave','3','Sweden'),
  ('Göteborg','19664','Ap #723-6979 Penatibus Av.','41','Sweden'),
  ('Norrköping','55166','6478 Ultricies Street','21','Sweden'),
  ('Mora','65694','Ap #480-6559 Malesuada Rd.','33','Sweden'),
  ('Avesta','54845','938-7834 Pharetra. St.','45','Sweden'),
  ('Hofors','03220','704-2106 Sit Rd.','8','Sweden'),
  ('Nässjö','49327','363-6762 Eget Rd.','13','Sweden'),
  ('Motala','78269','Ap #950-1161 Libero Ave','44','Sweden'),
  ('Nässjö','04795','224-8855 Cras Ave','49','Sweden');
INSERT INTO address (city,zip,street,house_number,country)
VALUES
  ('Jönköping','03877','Ap #634-7817 Donec Av.','18','Sweden'),
  ('Norrköping','15064','P.O. Box 727, 6198 Donec Rd.','41','Sweden'),
  ('Alingsås','32248','Ap #315-8953 Massa. Road','25','Sweden'),
  ('Jönköping','34657','252-5485 Amet, St.','7','Sweden'),
  ('Jönköping','15605','Ap #544-7878 Magna. Rd.','9','Sweden'),
  ('Mjölby','29336','P.O. Box 539, 4252 Laoreet Road','42','Sweden'),
  ('Borlänge','35612','586-5615 Fusce Road','0','Sweden'),
  ('Finspång','63204','Ap #914-6375 Risus, Road','35','Sweden'),
  ('Vänersborg','04363','Ap #207-6880 Mauris Av.','38','Sweden'),
  ('Linköping','75343','2092 Diam. Rd.','21','Sweden');
INSERT INTO address (city,zip,street,house_number,country)
VALUES
  ('Ockelbo','11872','Ap #676-6737 Fringilla Road','46','Sweden'),
  ('Göteborg','33795','Ap #304-5544 Felis St.','7','Sweden');

INSERT INTO address (city, zip, street, house_number, country)
SELECT
    (ARRAY['Stockholm', 'Göteborg', 'Malmö', 'Uppsala', 'Linköping', 'Örebro', 'Västerås', 'Umeå'])[i % 8 + 1] AS city,
    (10000 + i * 37 % 90000)::TEXT AS zip,
    CONCAT('Street ', i::TEXT) AS street,
    (i % 99 + 1)::TEXT AS house_number,
    'Sweden' AS country
FROM
    generate_series(0, 500000) AS i;


INSERT INTO phone_number (phone_number)
VALUES
  ('(554) 632-1211'),
  ('(674) 825-3632'),
  ('(551) 272-3715'),
  ('1-616-941-6054'),
  ('(297) 262-8852'),
  ('(733) 227-2914'),
  ('1-822-528-4166'),
  ('1-757-375-1167'),
  ('1-356-548-7092'),
  ('1-348-937-1306');
INSERT INTO phone_number (phone_number)
VALUES
  ('(523) 212-7346'),
  ('(663) 178-7769'),
  ('(672) 813-1111'),
  ('(510) 642-0570'),
  ('(562) 296-1742'),
  ('1-326-381-3815'),
  ('1-246-760-5947'),
  ('1-867-117-4871'),
  ('(896) 324-3471'),
  ('(608) 814-3745');
INSERT INTO phone_number (phone_number)
VALUES
  ('1-227-647-3868'),
  ('1-677-478-0815'),
  ('1-314-737-2680'),
  ('(908) 298-6213'),
  ('(540) 516-2818'),
  ('(776) 176-7757'),
  ('(762) 251-4259'),
  ('1-403-711-0838'),
  ('1-217-913-8137'),
  ('1-871-208-1294');
INSERT INTO phone_number (phone_number)
VALUES
  ('(268) 218-6654'),
  ('(409) 775-8714');

INSERT INTO phone_number (phone_number)
SELECT
    CONCAT('07', LPAD(i::TEXT, 8, '0')) AS phone_number
FROM
    generate_series(0, 500000) AS i;


INSERT INTO person_address (
    person_id,
    address_id,
    address_property
)
SELECT
    person.id,
    address.id,
    CASE apart_number.n
        WHEN 1 THEN 'Primary apartment'
        WHEN 2 THEN 'Secondary apartment'
        WHEN 3 THEN 'Summer house'
    END
FROM (
    SELECT
        id,
        ROW_NUMBER() OVER (ORDER BY personal_number) AS n
    FROM person
) AS person
CROSS JOIN LATERAL generate_series(
    1,
    CASE
        WHEN person.n % 157 = 0 THEN 3
        WHEN person.n % 59 = 0 THEN 2
        ELSE 1
    END
) AS apart_number(n)
JOIN (
    SELECT
        id,
        ROW_NUMBER() OVER (ORDER BY id) - 1 AS n
    FROM address
) AS address ON address.n = (person.n + apart_number.n - 2) % (SELECT COUNT(*) FROM address);

INSERT INTO person_phone_number (
    person_id,
    phone_number_id,
    phone_number_property
)
SELECT
    person.id,
    phone_number.id,
    CASE phone_count.n
        WHEN 1 THEN 'Mobile'
        WHEN 2 THEN 'Work'
    END
FROM (
    SELECT
        id,
        ROW_NUMBER() OVER (ORDER BY personal_number) AS n
    FROM person
) AS person
CROSS JOIN LATERAL generate_series(
    1,
    CASE
        WHEN person.n % 7 = 0 THEN 2
        ELSE 1
    END
) AS phone_count(n)
JOIN (
    SELECT
        id,
        ROW_NUMBER() OVER (ORDER BY id) - 1 AS n
    FROM phone_number
) AS phone_number ON phone_number.n = (person.n + phone_count.n - 2) % (SELECT COUNT(*) FROM phone_number);


INSERT INTO job_title (job_title_name)
VALUES
    ('Professor'),
    ('Senior Lecturer'),
    ('Associate Senior Lecturer / Assistant Professor'),
    ('Lecturer'),
    ('Artistic Teacher'),
    ('Adjunct Professor'),
    ('Guest Professor');


INSERT INTO skill (skill_name)
VALUES
    ('Pedagogy'),
    ('Academic Leadership'),
    ('Subject Expertise'),
    ('Research Methods'),
    ('Academic Writing'),
    ('Lab Expertise'),
    ('Project Management'),
    ('Systems Administration'),
    ('Bilingual Communication');


-- Circular dependency department <-> employee: the managers are set after the employees exist,
-- department.manager_employee_id is a deferred FK that is checked at COMMIT

BEGIN;

INSERT INTO department (department_name, manager_employee_id)
VALUES
    ('Computer Science', 0),
    ('Mathematics', 0),
    ('Electrical Engineering', 0),
    ('Electronics and Embedded Systems', 0);

INSERT INTO department(department_name, manager_employee_id)
SELECT
    CONCAT('Department ', i::TEXT) AS department_name,
    0 AS manager_employee_id
FROM generate_series(1, 1000) AS i;


INSERT INTO employee (
    employment_id,
    department_id,
    person_id,
    job_title_id
)
SELECT
    500000 + person.n,
    department.id,
    person.id,
    job_title.id
FROM (
    SELECT
        id,
        ROW_NUMBER() OVER (ORDER BY id) AS n
    FROM person
) AS person
JOIN (
    SELECT
        id,
        ROW_NUMBER() OVER (ORDER BY id) - 1 AS n
    FROM department
) AS department ON department.n = (person.n - 1) % (SELECT COUNT(*) FROM department)
JOIN job_title ON job_title.id = (
    SELECT id
    FROM job_title
    ORDER BY id
    OFFSET (person.n - 1) % (SELECT COUNT(*) FROM job_title)
    LIMIT 1
);


UPDATE department
SET manager_employee_id = manager.id
FROM (
    SELECT
        id,
        ROW_NUMBER() OVER (ORDER BY id) AS n
    FROM department
) AS department_order
JOIN (
    SELECT
        id,
        ROW_NUMBER() OVER (ORDER BY id) AS n
    FROM employee
) AS manager ON manager.n = department_order.n
WHERE department.id = department_order.id;


UPDATE employee
SET supervisor_id = CASE
    WHEN employee.id = department.manager_employee_id THEN (SELECT MIN(id) FROM employee)
    ELSE department.manager_employee_id
END
FROM department
WHERE department.id = employee.department_id
  AND employee.id <> (SELECT MIN(id) FROM employee);

COMMIT;


INSERT INTO employee_skill (
    employee_id,
    skill_id
)
SELECT
    employee.id,
    skill.id
FROM (
    SELECT
        id,
        ROW_NUMBER() OVER (ORDER BY id) AS n
    FROM employee
) AS employee
CROSS JOIN LATERAL generate_series(
    1,
    (employee.n - 1) % 7 + 1
) AS skill_count(n)
JOIN skill ON skill.id = (
    SELECT id
    FROM skill
    ORDER BY id
    OFFSET (
        28 * ((employee.n - 1) / 7)
        + ((employee.n - 1) % 7) * ((employee.n - 1) % 7 + 1) / 2
        + skill_count.n - 1
    ) % (SELECT COUNT(*) FROM skill)
    LIMIT 1
);


INSERT INTO employee_salary (
    salary,
    valid_from,
    employee_id
)
SELECT
    ROUND((30000 + employee.n * 7919 % 40000) * CASE salary_version.n
        WHEN 1 THEN 1.00
        WHEN 2 THEN 1.05
    END),
    CASE salary_version.n
        WHEN 1 THEN MAKE_DATE(2023, 01, 01)
        WHEN 2 THEN MAKE_DATE(2025, 01, 01)
    END,
    employee.id
FROM (
    SELECT
        id,
        ROW_NUMBER() OVER (ORDER BY id) AS n
    FROM employee
) AS employee
CROSS JOIN LATERAL generate_series(
    1,
    CASE
        WHEN employee.n % 3 = 0 THEN 2
        ELSE 1
    END
) AS salary_version(n);


INSERT INTO policy (policy_name, policy_value)
VALUES ('allocation_rule', 4);


INSERT INTO teaching_activity (activity_name, multiplication_factor)
VALUES
    ('Lecture', 3.6),
    ('Lab', 2.4),
    ('Tutorial', 2.4),
    ('Seminar', 1.8),
    ('Others', 1.0),
    ('Examination', 1.0),
    ('Administration', 1.0);


INSERT INTO derived_activity_formula (teaching_activity_id, base_hours, hours_per_student, hours_per_hp)
VALUES
    ((SELECT id FROM teaching_activity WHERE activity_name = 'Examination'), 32, 0.725, 0),
    ((SELECT id FROM teaching_activity WHERE activity_name = 'Administration'), 28, 0.2, 2);


INSERT INTO planned_activity (
    planned_hours,
    teaching_activity_id,
    course_instance_id
)
SELECT
    CASE
        WHEN derived_activity_formula.id IS NULL
        THEN 10 + (course_instance.n * 7 + teaching_activity.n * 13) % 60
    END,
    teaching_activity.id,
    course_instance.id
FROM (
    SELECT
        id,
        ROW_NUMBER() OVER (ORDER BY id) AS n
    FROM course_instance
) AS course_instance
CROSS JOIN (
    SELECT
        id,
        ROW_NUMBER() OVER (ORDER BY id) AS n
    FROM teaching_activity
) AS teaching_activity
LEFT JOIN derived_activity_formula
    ON derived_activity_formula.teaching_activity_id = teaching_activity.id
WHERE derived_activity_formula.id IS NOT NULL
   OR teaching_activity.n = 1
   OR (course_instance.n + teaching_activity.n) % 3 <> 0;


-- Trigger disabled during the bulk load: the generated data keeps every teacher within the limit

ALTER TABLE teaching_allocation DISABLE TRIGGER trigger_4_instances_each_study_period;

INSERT INTO teaching_allocation (
    planned_activity_id,
    employee_id,
    allocation_hours
)
SELECT
    planned_activity.id,
    employee.id,
    CASE teacher.n
        WHEN 1 THEN planned_activity.total_hours
            - (planned_activity.teacher_count - 1) * (planned_activity.total_hours / planned_activity.teacher_count)
        ELSE planned_activity.total_hours / planned_activity.teacher_count
    END
FROM (
    SELECT
        planned_activity.id,
        course_instance.k,
        teaching_activity.n AS m,
        teaching_activity.activity_name,
        CAST(COALESCE(
            planned_activity.planned_hours,
            ROUND(
                derived_activity_formula.base_hours
                + derived_activity_formula.hours_per_student * course_instance.num_students
                + derived_activity_formula.hours_per_hp * course_layout.hp
            )
        ) AS INT) AS total_hours,
        CASE
            WHEN teaching_activity.activity_name = 'Administration' THEN 1
            ELSE 1 + (course_instance.k + teaching_activity.n) % 2
        END AS teacher_count
    FROM planned_activity
    JOIN (
        SELECT
            id,
            course_layout_id,
            num_students,
            ROW_NUMBER() OVER (PARTITION BY academic_period_id ORDER BY id) AS k
        FROM course_instance
    ) AS course_instance ON course_instance.id = planned_activity.course_instance_id
    JOIN course_layout ON course_layout.id = course_instance.course_layout_id
    JOIN (
        SELECT
            id,
            activity_name,
            ROW_NUMBER() OVER (ORDER BY id) AS n
        FROM teaching_activity
    ) AS teaching_activity ON teaching_activity.id = planned_activity.teaching_activity_id
    LEFT JOIN derived_activity_formula
        ON derived_activity_formula.teaching_activity_id = teaching_activity.id
) AS planned_activity
CROSS JOIN LATERAL generate_series(
    1,
    planned_activity.teacher_count
) AS teacher(n)
JOIN (
    SELECT
        id,
        ROW_NUMBER() OVER (ORDER BY id) - 1 AS n
    FROM employee
) AS employee ON employee.n = CASE
        WHEN planned_activity.activity_name = 'Administration' AND planned_activity.k <= 4 THEN 0
        ELSE (planned_activity.k - 1) * 4 + (planned_activity.m + teacher.n - 2) % 4
    END % (SELECT COUNT(*) FROM employee);

ALTER TABLE teaching_allocation ENABLE TRIGGER trigger_4_instances_each_study_period;

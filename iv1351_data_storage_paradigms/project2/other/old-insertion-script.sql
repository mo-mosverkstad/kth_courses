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
),
years AS (
    SELECT
        year
    FROM generate_series(2023, 2026) AS year
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
        LPAD(course.id::TEXT, 3, '0'),
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
JOIN address ON address.id = (
    SELECT id
    FROM address
    ORDER BY id
    OFFSET (person.n + apart_number.n - 2) % (SELECT COUNT(*) FROM address)
    LIMIT 1
);

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
JOIN phone_number ON phone_number.id = (
    SELECT id
    FROM phone_number
    ORDER BY id
    OFFSET (person.n + phone_count.n - 2) % (SELECT COUNT(*) FROM phone_number)
    LIMIT 1
);


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


INSERT INTO employee (employment_id, department_id, person_id, job_title_id)
SELECT v.employment_id, d.id, p.id, j.id
FROM (
    SELECT 500001 AS employment_id, '4689185576' AS personal_number, 'Computer Science' AS department_name, 'Professor' AS job_title_name
) AS v
INNER JOIN department AS d
    ON d.department_name = v.department_name
INNER JOIN person AS p
    ON p.personal_number = v.personal_number
INNER JOIN job_title AS j
    ON j.job_title_name = v.job_title_name;

INSERT INTO employee (employment_id, department_id, person_id, job_title_id, supervisor_id)
SELECT v.employment_id, d.id, p.id, j.id, s.id
FROM (
    SELECT 500002 AS employment_id, '4265395646' AS personal_number, 'Mathematics' AS department_name, 'Professor' AS job_title_name, 500001 AS supervisor_employment_id
    UNION ALL SELECT 500003, '1544659622', 'Electrical Engineering', 'Professor', 500001
    UNION ALL SELECT 500004, '3286345052', 'Electronics and Embedded Systems', 'Senior Lecturer', 500001
) AS v
INNER JOIN department AS d
    ON d.department_name = v.department_name
INNER JOIN person AS p
    ON p.personal_number = v.personal_number
INNER JOIN job_title AS j
    ON j.job_title_name = v.job_title_name
INNER JOIN employee AS s
    ON s.employment_id = v.supervisor_employment_id;

INSERT INTO employee (employment_id, department_id, person_id, job_title_id, supervisor_id)
SELECT v.employment_id, d.id, p.id, j.id, s.id
FROM (
    SELECT 500005 AS employment_id, '6680931650' AS personal_number, 'Computer Science' AS department_name, 'Senior Lecturer' AS job_title_name, 500001 AS supervisor_employment_id
    UNION ALL SELECT 500006, '6259118532', 'Computer Science', 'Associate Senior Lecturer / Assistant Professor', 500001
    UNION ALL SELECT 500007, '8580989374', 'Computer Science', 'Lecturer', 500001
    UNION ALL SELECT 500008, '1044144913', 'Computer Science', 'Adjunct Professor', 500001
    UNION ALL SELECT 500009, '1191676461', 'Mathematics', 'Senior Lecturer', 500002
    UNION ALL SELECT 500010, '1238682057', 'Mathematics', 'Lecturer', 500002
    UNION ALL SELECT 500011, '6861061717', 'Mathematics', 'Associate Senior Lecturer / Assistant Professor', 500002
    UNION ALL SELECT 500012, '6084815807', 'Mathematics', 'Guest Professor', 500002
    UNION ALL SELECT 500013, '5006765376', 'Electrical Engineering', 'Senior Lecturer', 500003
    UNION ALL SELECT 500014, '3469756492', 'Electrical Engineering', 'Lecturer', 500003
    UNION ALL SELECT 500015, '7672554955', 'Electrical Engineering', 'Artistic Teacher', 500003
    UNION ALL SELECT 500016, '6025829417', 'Electronics and Embedded Systems', 'Lecturer', 500004
    UNION ALL SELECT 500017, '8480022451', 'Electronics and Embedded Systems', 'Associate Senior Lecturer / Assistant Professor', 500004
    UNION ALL SELECT 500018, '8171942841', 'Electronics and Embedded Systems', 'Senior Lecturer', 500004
    UNION ALL SELECT 500019, '2734803456', 'Computer Science', 'Lecturer', 500001
    UNION ALL SELECT 500020, '6658263404', 'Mathematics', 'Lecturer', 500002
) AS v
INNER JOIN department AS d
    ON d.department_name = v.department_name
INNER JOIN person AS p
    ON p.personal_number = v.personal_number
INNER JOIN job_title AS j
    ON j.job_title_name = v.job_title_name
INNER JOIN employee AS s
    ON s.employment_id = v.supervisor_employment_id;


UPDATE department
SET manager_employee_id = (SELECT id FROM employee WHERE employment_id = 500001)
WHERE department_name = 'Computer Science';

UPDATE department
SET manager_employee_id = (SELECT id FROM employee WHERE employment_id = 500002)
WHERE department_name = 'Mathematics';

UPDATE department
SET manager_employee_id = (SELECT id FROM employee WHERE employment_id = 500003)
WHERE department_name = 'Electrical Engineering';

UPDATE department
SET manager_employee_id = (SELECT id FROM employee WHERE employment_id = 500004)
WHERE department_name = 'Electronics and Embedded Systems';

COMMIT;


INSERT INTO employee_skill (employee_id, skill_id)
SELECT e.id, s.id
FROM (
    SELECT 500001 AS employment_id, 'Academic Leadership' AS skill_name
    UNION ALL SELECT 500001, 'Subject Expertise'
    UNION ALL SELECT 500001, 'Pedagogy'
    UNION ALL SELECT 500002, 'Academic Leadership'
    UNION ALL SELECT 500002, 'Research Methods'
    UNION ALL SELECT 500003, 'Academic Leadership'
    UNION ALL SELECT 500003, 'Lab Expertise'
    UNION ALL SELECT 500004, 'Project Management'
    UNION ALL SELECT 500004, 'Subject Expertise'
    UNION ALL SELECT 500005, 'Pedagogy'
    UNION ALL SELECT 500005, 'Subject Expertise'
    UNION ALL SELECT 500006, 'Research Methods'
    UNION ALL SELECT 500006, 'Academic Writing'
    UNION ALL SELECT 500007, 'Pedagogy'
    UNION ALL SELECT 500008, 'Systems Administration'
) AS v
INNER JOIN employee AS e
    ON e.employment_id = v.employment_id
INNER JOIN skill AS s
    ON s.skill_name = v.skill_name;
INSERT INTO employee_skill (employee_id, skill_id)
SELECT e.id, s.id
FROM (
    SELECT 500009 AS employment_id, 'Pedagogy' AS skill_name
    UNION ALL SELECT 500009, 'Subject Expertise'
    UNION ALL SELECT 500010, 'Pedagogy'
    UNION ALL SELECT 500011, 'Research Methods'
    UNION ALL SELECT 500012, 'Academic Writing'
    UNION ALL SELECT 500013, 'Lab Expertise'
    UNION ALL SELECT 500014, 'Pedagogy'
    UNION ALL SELECT 500015, 'Bilingual Communication'
    UNION ALL SELECT 500016, 'Lab Expertise'
    UNION ALL SELECT 500017, 'Lab Expertise'
    UNION ALL SELECT 500017, 'Research Methods'
    UNION ALL SELECT 500018, 'Project Management'
    UNION ALL SELECT 500019, 'Pedagogy'
    UNION ALL SELECT 500019, 'Bilingual Communication'
    UNION ALL SELECT 500020, 'Subject Expertise'
) AS v
INNER JOIN employee AS e
    ON e.employment_id = v.employment_id
INNER JOIN skill AS s
    ON s.skill_name = v.skill_name;


INSERT INTO employee_salary (salary, valid_from, employee_id)
SELECT v.salary, CAST(v.valid_from AS DATE), e.id
FROM (
    SELECT 500001 AS employment_id, 72000 AS salary, '2023-01-01' AS valid_from
    UNION ALL SELECT 500002, 70000, '2023-01-01'
    UNION ALL SELECT 500003, 69000, '2023-01-01'
    UNION ALL SELECT 500004, 58000, '2023-01-01'
    UNION ALL SELECT 500005, 56000, '2023-01-01'
    UNION ALL SELECT 500006, 50000, '2023-01-01'
    UNION ALL SELECT 500007, 45000, '2023-01-01'
    UNION ALL SELECT 500008, 30000, '2023-01-01'
    UNION ALL SELECT 500009, 57000, '2023-01-01'
    UNION ALL SELECT 500010, 44000, '2023-01-01'
    UNION ALL SELECT 500011, 49500, '2023-01-01'
    UNION ALL SELECT 500012, 40000, '2023-01-01'
) AS v
INNER JOIN employee AS e
    ON e.employment_id = v.employment_id;
INSERT INTO employee_salary (salary, valid_from, employee_id)
SELECT v.salary, CAST(v.valid_from AS DATE), e.id
FROM (
    SELECT 500013 AS employment_id, 56500 AS salary, '2023-01-01' AS valid_from
    UNION ALL SELECT 500014, 43500, '2023-01-01'
    UNION ALL SELECT 500015, 42000, '2023-01-01'
    UNION ALL SELECT 500016, 44500, '2023-01-01'
    UNION ALL SELECT 500017, 50500, '2023-01-01'
    UNION ALL SELECT 500018, 57500, '2023-01-01'
    UNION ALL SELECT 500019, 43000, '2023-01-01'
    UNION ALL SELECT 500020, 44000, '2023-01-01'
    UNION ALL SELECT 500001, 75000, '2025-01-01'
    UNION ALL SELECT 500003, 71500, '2025-01-01'
    UNION ALL SELECT 500005, 59000, '2025-01-01'
    UNION ALL SELECT 500006, 52000, '2025-01-01'
    UNION ALL SELECT 500009, 59500, '2025-01-01'
) AS v
INNER JOIN employee AS e
    ON e.employment_id = v.employment_id;


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


INSERT INTO planned_activity (planned_hours, teaching_activity_id, course_instance_id)
SELECT v.planned_hours, ta.id, ci.id
FROM (
    SELECT '2025-50022' AS instance_id, 'Lecture' AS activity_name, 20 AS planned_hours
    UNION ALL SELECT '2025-50022', 'Tutorial', 80
    UNION ALL SELECT '2025-50022', 'Lab', 40
    UNION ALL SELECT '2025-50022', 'Seminar', 80
    UNION ALL SELECT '2025-50022', 'Others', 650
    UNION ALL SELECT '2025-50022', 'Examination', NULL
    UNION ALL SELECT '2025-50022', 'Administration', NULL
) AS v
INNER JOIN teaching_activity AS ta
    ON ta.activity_name = v.activity_name
INNER JOIN course_instance AS ci
    ON ci.instance_id = v.instance_id;
INSERT INTO planned_activity (planned_hours, teaching_activity_id, course_instance_id)
SELECT v.planned_hours, ta.id, ci.id
FROM (
    SELECT '2025-50011' AS instance_id, 'Lecture' AS activity_name, 44 AS planned_hours
    UNION ALL SELECT '2025-50011', 'Seminar', 64
    UNION ALL SELECT '2025-50011', 'Others', 200
    UNION ALL SELECT '2025-50011', 'Examination', NULL
    UNION ALL SELECT '2025-50011', 'Administration', NULL
) AS v
INNER JOIN teaching_activity AS ta
    ON ta.activity_name = v.activity_name
INNER JOIN course_instance AS ci
    ON ci.instance_id = v.instance_id;
INSERT INTO planned_activity (planned_hours, teaching_activity_id, course_instance_id)
SELECT v.planned_hours, ta.id, ci.id
FROM (
    SELECT '2024-50022' AS instance_id, 'Lecture' AS activity_name, 20 AS planned_hours
    UNION ALL SELECT '2024-50022', 'Lab', 40
    UNION ALL SELECT '2024-50022', 'Seminar', 60
    UNION ALL SELECT '2024-50022', 'Examination', NULL
    UNION ALL SELECT '2024-50022', 'Administration', NULL
    UNION ALL SELECT '2024-50011', 'Lecture', 44
    UNION ALL SELECT '2024-50011', 'Seminar', 60
    UNION ALL SELECT '2024-50011', 'Examination', NULL
    UNION ALL SELECT '2024-50011', 'Administration', NULL
) AS v
INNER JOIN teaching_activity AS ta
    ON ta.activity_name = v.activity_name
INNER JOIN course_instance AS ci
    ON ci.instance_id = v.instance_id;
INSERT INTO planned_activity (planned_hours, teaching_activity_id, course_instance_id)
SELECT v.planned_hours, ta.id, ci.id
FROM (
    SELECT '2025-50072' AS instance_id, 'Lecture' AS activity_name, 30 AS planned_hours
    UNION ALL SELECT '2025-50072', 'Lab', 60
    UNION ALL SELECT '2025-50122', 'Lecture', 24
    UNION ALL SELECT '2025-50132', 'Lab', 32
) AS v
INNER JOIN teaching_activity AS ta
    ON ta.activity_name = v.activity_name
INNER JOIN course_instance AS ci
    ON ci.instance_id = v.instance_id;


INSERT INTO teaching_allocation (planned_activity_id, employee_id, allocation_hours)
SELECT pa.id, e.id, v.allocation_hours
FROM (
    SELECT '2025-50022' AS instance_id, 'Lecture' AS activity_name, 500001 AS employment_id, 20 AS allocation_hours
    UNION ALL SELECT '2025-50022', 'Tutorial', 500007, 40
    UNION ALL SELECT '2025-50022', 'Tutorial', 500019, 40
    UNION ALL SELECT '2025-50022', 'Lab', 500006, 20
    UNION ALL SELECT '2025-50022', 'Lab', 500019, 20
    UNION ALL SELECT '2025-50022', 'Seminar', 500005, 40
    UNION ALL SELECT '2025-50022', 'Seminar', 500007, 40
    UNION ALL SELECT '2025-50022', 'Others', 500001, 200
    UNION ALL SELECT '2025-50022', 'Others', 500005, 200
    UNION ALL SELECT '2025-50022', 'Others', 500006, 150
    UNION ALL SELECT '2025-50022', 'Others', 500007, 100
    UNION ALL SELECT '2025-50022', 'Examination', 500001, 50
    UNION ALL SELECT '2025-50022', 'Examination', 500005, 47
    UNION ALL SELECT '2025-50022', 'Administration', 500001, 61
) AS v
INNER JOIN course_instance AS ci
    ON ci.instance_id = v.instance_id
INNER JOIN teaching_activity AS ta
    ON ta.activity_name = v.activity_name
INNER JOIN planned_activity AS pa
    ON pa.course_instance_id = ci.id
    AND pa.teaching_activity_id = ta.id
INNER JOIN employee AS e
    ON e.employment_id = v.employment_id;
INSERT INTO teaching_allocation (planned_activity_id, employee_id, allocation_hours)
SELECT pa.id, e.id, v.allocation_hours
FROM (
    SELECT '2025-50011' AS instance_id, 'Lecture' AS activity_name, 500009 AS employment_id, 44 AS allocation_hours
    UNION ALL SELECT '2025-50011', 'Seminar', 500005, 32
    UNION ALL SELECT '2025-50011', 'Seminar', 500010, 32
    UNION ALL SELECT '2025-50011', 'Others', 500009, 100
    UNION ALL SELECT '2025-50011', 'Others', 500010, 50
    UNION ALL SELECT '2025-50011', 'Others', 500005, 50
    UNION ALL SELECT '2025-50011', 'Examination', 500009, 60
    UNION ALL SELECT '2025-50011', 'Examination', 500010, 52
    UNION ALL SELECT '2025-50011', 'Administration', 500009, 65
) AS v
INNER JOIN course_instance AS ci
    ON ci.instance_id = v.instance_id
INNER JOIN teaching_activity AS ta
    ON ta.activity_name = v.activity_name
INNER JOIN planned_activity AS pa
    ON pa.course_instance_id = ci.id
    AND pa.teaching_activity_id = ta.id
INNER JOIN employee AS e
    ON e.employment_id = v.employment_id;
INSERT INTO teaching_allocation (planned_activity_id, employee_id, allocation_hours)
SELECT pa.id, e.id, v.allocation_hours
FROM (
    SELECT '2024-50022' AS instance_id, 'Lecture' AS activity_name, 500001 AS employment_id, 20 AS allocation_hours
    UNION ALL SELECT '2024-50022', 'Lab', 500006, 40
    UNION ALL SELECT '2024-50022', 'Seminar', 500005, 60
    UNION ALL SELECT '2024-50022', 'Examination', 500001, 94
    UNION ALL SELECT '2024-50022', 'Administration', 500001, 60
    UNION ALL SELECT '2024-50011', 'Lecture', 500009, 44
    UNION ALL SELECT '2024-50011', 'Seminar', 500010, 60
    UNION ALL SELECT '2024-50011', 'Examination', 500009, 108
    UNION ALL SELECT '2024-50011', 'Administration', 500009, 64
) AS v
INNER JOIN course_instance AS ci
    ON ci.instance_id = v.instance_id
INNER JOIN teaching_activity AS ta
    ON ta.activity_name = v.activity_name
INNER JOIN planned_activity AS pa
    ON pa.course_instance_id = ci.id
    AND pa.teaching_activity_id = ta.id
INNER JOIN employee AS e
    ON e.employment_id = v.employment_id;
INSERT INTO teaching_allocation (planned_activity_id, employee_id, allocation_hours)
SELECT pa.id, e.id, v.allocation_hours
FROM (
    SELECT '2025-50072' AS instance_id, 'Lecture' AS activity_name, 500005 AS employment_id, 30 AS allocation_hours
    UNION ALL SELECT '2025-50072', 'Lab', 500008, 30
    UNION ALL SELECT '2025-50072', 'Lab', 500019, 30
    UNION ALL SELECT '2025-50122', 'Lecture', 500005, 24
    UNION ALL SELECT '2025-50132', 'Lab', 500005, 16
    UNION ALL SELECT '2025-50132', 'Lab', 500017, 16
) AS v
INNER JOIN course_instance AS ci
    ON ci.instance_id = v.instance_id
INNER JOIN teaching_activity AS ta
    ON ta.activity_name = v.activity_name
INNER JOIN planned_activity AS pa
    ON pa.course_instance_id = ci.id
    AND pa.teaching_activity_id = ta.id
INNER JOIN employee AS e
    ON e.employment_id = v.employment_id;

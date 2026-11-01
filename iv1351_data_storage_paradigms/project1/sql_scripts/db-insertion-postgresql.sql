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
    v.min_students,
    v.max_students,
    v.hp,
    1 AS version,
    c.id
FROM (
    SELECT 'IX1500' AS course_code, 1 AS min_students, 120 AS max_students, 7.5 AS hp
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
INNER JOIN course AS c
    ON c.course_code = v.course_code;


INSERT INTO period (period_name)
VALUES ('P1'), ('P2'), ('P3'), ('P4');


INSERT INTO academic_period (academic_year, period_id, start_date, end_date)
VALUES
    (2023, (SELECT id FROM period WHERE period_name = 'P1'), '2023-01-01', '2023-03-31'),
    (2023, (SELECT id FROM period WHERE period_name = 'P2'), '2023-04-01', '2023-06-30'),
    (2023, (SELECT id FROM period WHERE period_name = 'P3'), '2023-07-01', '2023-09-30'),
    (2023, (SELECT id FROM period WHERE period_name = 'P4'), '2023-10-01', '2023-12-31'),
    (2024, (SELECT id FROM period WHERE period_name = 'P1'), '2024-01-01', '2024-03-31'),
    (2024, (SELECT id FROM period WHERE period_name = 'P2'), '2024-04-01', '2024-06-30'),
    (2024, (SELECT id FROM period WHERE period_name = 'P3'), '2024-07-01', '2024-09-30'),
    (2024, (SELECT id FROM period WHERE period_name = 'P4'), '2024-10-01', '2024-12-31'),
    (2025, (SELECT id FROM period WHERE period_name = 'P1'), '2025-01-01', '2025-03-31'),
    (2025, (SELECT id FROM period WHERE period_name = 'P2'), '2025-04-01', '2025-06-30'),
    (2025, (SELECT id FROM period WHERE period_name = 'P3'), '2025-07-01', '2025-09-30'),
    (2025, (SELECT id FROM period WHERE period_name = 'P4'), '2025-10-01', '2025-12-31');


INSERT INTO course_instance (
    instance_id,
    course_layout_id,
    academic_period_id,
    num_students
)
SELECT
    -- e.g. '2025-50011': year, '-5', 3-digit course id, period number
    CONCAT(v.study_year, '-5', LPAD(CAST(c.id AS CHAR(3)), 3, '0'), RIGHT(v.study_period, 1)),
    cl.id,
    ap.id,
    v.num_students
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
INNER JOIN course AS c
    ON c.course_code = v.course_code
INNER JOIN course_layout AS cl
    ON cl.course_id = c.id
    AND cl.version = 1
INNER JOIN period AS p
    ON p.period_name = v.study_period
INNER JOIN academic_period AS ap
    ON ap.academic_year = v.study_year
    AND ap.period_id = p.id;


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


INSERT INTO person_address (person_id, address_id, address_property)
SELECT p.id, a.id, v.address_property
FROM (
    SELECT '4689185576' AS personal_number, '41830' AS zip, 'home' AS address_property
    UNION ALL SELECT '4265395646', '74961', 'home'
    UNION ALL SELECT '1544659622', '72261', NULL
    UNION ALL SELECT '3286345052', '72347', 'home'
    UNION ALL SELECT '6680931650', '21615', 'home'
    UNION ALL SELECT '6259118532', '58670', NULL
    UNION ALL SELECT '8580989374', '28101', 'home'
    UNION ALL SELECT '1044144913', '73831', 'office'
    UNION ALL SELECT '1191676461', '58434', 'home'
    UNION ALL SELECT '1238682057', '13222', NULL
) AS v
INNER JOIN person AS p
    ON p.personal_number = v.personal_number
INNER JOIN address AS a
    ON a.zip = v.zip;
INSERT INTO person_address (person_id, address_id, address_property)
SELECT p.id, a.id, v.address_property
FROM (
    SELECT '6861061717' AS personal_number, '04510' AS zip, 'home' AS address_property
    UNION ALL SELECT '6084815807', '65685', 'home'
    UNION ALL SELECT '5006765376', '19664', NULL
    UNION ALL SELECT '3469756492', '55166', 'home'
    UNION ALL SELECT '7672554955', '65694', 'home'
    UNION ALL SELECT '6025829417', '54845', NULL
    UNION ALL SELECT '8480022451', '03220', 'home'
    UNION ALL SELECT '8171942841', '49327', 'home'
    UNION ALL SELECT '2734803456', '78269', 'office'
    UNION ALL SELECT '6658263404', '04795', 'home'
) AS v
INNER JOIN person AS p
    ON p.personal_number = v.personal_number
INNER JOIN address AS a
    ON a.zip = v.zip;


INSERT INTO person_phone_number (person_id, phone_number_id, phone_number_property)
SELECT p.id, pn.id, v.phone_number_property
FROM (
    SELECT '4689185576' AS personal_number, '(554) 632-1211' AS phone_number, 'mobile' AS phone_number_property
    UNION ALL SELECT '4265395646', '(674) 825-3632', 'mobile'
    UNION ALL SELECT '1544659622', '(551) 272-3715', 'work'
    UNION ALL SELECT '3286345052', '1-616-941-6054', NULL
    UNION ALL SELECT '6680931650', '(297) 262-8852', 'mobile'
    UNION ALL SELECT '6680931650', '(551) 272-3715', 'work'
    UNION ALL SELECT '6259118532', '(733) 227-2914', 'mobile'
    UNION ALL SELECT '8580989374', '1-822-528-4166', NULL
    UNION ALL SELECT '1044144913', '1-757-375-1167', 'work'
    UNION ALL SELECT '1191676461', '1-356-548-7092', 'mobile'
    UNION ALL SELECT '1238682057', '1-348-937-1306', 'mobile'
) AS v
INNER JOIN person AS p
    ON p.personal_number = v.personal_number
INNER JOIN phone_number AS pn
    ON pn.phone_number = v.phone_number;
INSERT INTO person_phone_number (person_id, phone_number_id, phone_number_property)
SELECT p.id, pn.id, v.phone_number_property
FROM (
    SELECT '6861061717' AS personal_number, '(523) 212-7346' AS phone_number, NULL AS phone_number_property
    UNION ALL SELECT '6084815807', '(663) 178-7769', 'work'
    UNION ALL SELECT '5006765376', '(672) 813-1111', 'mobile'
    UNION ALL SELECT '3469756492', '(510) 642-0570', 'mobile'
    UNION ALL SELECT '7672554955', '(562) 296-1742', NULL
    UNION ALL SELECT '6025829417', '1-326-381-3815', 'mobile'
    UNION ALL SELECT '8480022451', '1-246-760-5947', 'work'
    UNION ALL SELECT '8171942841', '1-867-117-4871', 'mobile'
    UNION ALL SELECT '2734803456', '(896) 324-3471', 'mobile'
    UNION ALL SELECT '6658263404', '(608) 814-3745', NULL
) AS v
INNER JOIN person AS p
    ON p.personal_number = v.personal_number
INNER JOIN phone_number AS pn
    ON pn.phone_number = v.phone_number;


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


INSERT INTO allocation_rule (max_courses)
VALUES (4);


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

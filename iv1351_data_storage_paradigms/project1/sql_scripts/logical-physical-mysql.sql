-- course layout tables

CREATE TABLE course (
    id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    course_code VARCHAR(10) NOT NULL UNIQUE,
    course_name VARCHAR(128) NOT NULL
);

CREATE TABLE course_layout (
    id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    min_students INT NOT NULL,
    max_students INT,
    hp NUMERIC(4,1) NOT NULL,
    version INT NOT NULL,
    course_id INT NOT NULL,

    FOREIGN KEY (course_id) REFERENCES course(id) ON UPDATE CASCADE,
    UNIQUE (course_id, version),
    CHECK (min_students > 0),
    CHECK (max_students >= min_students)
);

CREATE TABLE period (
    id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    period_name VARCHAR(16) NOT NULL UNIQUE
);

CREATE TABLE academic_period (
    id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    academic_year INT NOT NULL,
    period_id INT NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,

    FOREIGN KEY (period_id) REFERENCES period(id) ON UPDATE CASCADE,
    UNIQUE (academic_year, period_id),
    CHECK (academic_year > 1970),
    CHECK (start_date < end_date)
);

CREATE TABLE course_instance (
    id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    instance_id VARCHAR(16) NOT NULL UNIQUE,
    course_layout_id INT NOT NULL,
    academic_period_id INT NOT NULL,
    num_students INT NOT NULL,

    FOREIGN KEY (course_layout_id) REFERENCES course_layout(id) ON UPDATE CASCADE,
    FOREIGN KEY (academic_period_id) REFERENCES academic_period(id) ON UPDATE CASCADE,
    UNIQUE (course_layout_id, academic_period_id),
    CHECK (num_students >= 0)
);

-- People, employees and departments

CREATE TABLE department (
    id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    department_name VARCHAR(128) NOT NULL UNIQUE,
    manager_employee_id INT NOT NULL
);

CREATE TABLE person (
    id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    personal_number VARCHAR(32) UNIQUE,
    first_name VARCHAR(128) NOT NULL,
    last_name VARCHAR(128) NOT NULL
);

CREATE TABLE job_title (
    id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    job_title_name VARCHAR(128) NOT NULL UNIQUE
);

CREATE TABLE employee (
    id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    employment_id INT NOT NULL UNIQUE,
    department_id INT NOT NULL,
    person_id INT NOT NULL UNIQUE,
    job_title_id INT NOT NULL,
    supervisor_id INT,

    FOREIGN KEY (department_id) REFERENCES department(id) ON UPDATE CASCADE,
    FOREIGN KEY (person_id) REFERENCES person(id) ON UPDATE CASCADE,
    FOREIGN KEY (job_title_id) REFERENCES job_title(id) ON UPDATE CASCADE,
    FOREIGN KEY (supervisor_id) REFERENCES employee(id) ON UPDATE CASCADE
);

-- Circular dependency:
-- department.manager_employee_id -> employee.id
-- employee.department_id -> department.id

ALTER TABLE department
ADD CONSTRAINT fk_department_manager FOREIGN KEY (manager_employee_id) REFERENCES employee(id) ON UPDATE CASCADE;

-- Affiliated properties: address, phone number, skill, salary

CREATE TABLE address (
    id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    city VARCHAR(128) NOT NULL,
    zip VARCHAR(16) NOT NULL,
    street VARCHAR(128) NOT NULL,
    house_number VARCHAR(16) NOT NULL,
    country VARCHAR(128) NOT NULL,

    UNIQUE (city, zip, street, house_number, country)
);

CREATE TABLE person_address (
    address_id INT NOT NULL,
    person_id INT NOT NULL,
    address_property VARCHAR(128),

    PRIMARY KEY (address_id, person_id),
    FOREIGN KEY (address_id) REFERENCES address(id) ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (person_id) REFERENCES person(id) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE phone_number (
    id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    phone_number VARCHAR(32) NOT NULL UNIQUE
);

CREATE TABLE person_phone_number (
    phone_number_id INT NOT NULL,
    person_id INT NOT NULL,
    phone_number_property VARCHAR(128),

    PRIMARY KEY (phone_number_id, person_id),
    FOREIGN KEY (phone_number_id) REFERENCES phone_number(id) ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (person_id) REFERENCES person(id) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE skill (
    id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    skill_name VARCHAR(128) NOT NULL UNIQUE
);

CREATE TABLE employee_skill (
    skill_id INT NOT NULL,
    employee_id INT NOT NULL,

    PRIMARY KEY (skill_id, employee_id),
    FOREIGN KEY (skill_id) REFERENCES skill(id) ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (employee_id) REFERENCES employee(id) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE employee_salary (
    id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    salary NUMERIC(12,2) NOT NULL,
    valid_from DATE NOT NULL,
    employee_id INT NOT NULL,

    FOREIGN KEY (employee_id) REFERENCES employee(id) ON UPDATE CASCADE ON DELETE CASCADE,
    UNIQUE (employee_id, valid_from)
);

-- Allocation rule

CREATE TABLE allocation_rule (
    id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    max_courses INT NOT NULL
);

-- Activity and formula

CREATE TABLE teaching_activity (
    id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    activity_name VARCHAR(128) NOT NULL UNIQUE,
    multiplication_factor NUMERIC(4,2) NOT NULL
);

CREATE TABLE derived_activity_formula (
    id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    teaching_activity_id INT NOT NULL UNIQUE,
    base_hours NUMERIC(6,2) NOT NULL DEFAULT 0,
    hours_per_student NUMERIC(6,3) NOT NULL,
    hours_per_hp NUMERIC(6,2) NOT NULL,

    FOREIGN KEY (teaching_activity_id) REFERENCES teaching_activity(id) ON UPDATE CASCADE ON DELETE CASCADE
);

-- Planned activity and allocations

CREATE TABLE planned_activity (
    id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    planned_hours INT,
    teaching_activity_id INT NOT NULL,
    course_instance_id INT NOT NULL,

    FOREIGN KEY (teaching_activity_id) REFERENCES teaching_activity(id) ON UPDATE CASCADE,
    FOREIGN KEY (course_instance_id) REFERENCES course_instance(id) ON UPDATE CASCADE ON DELETE CASCADE,
    UNIQUE (course_instance_id, teaching_activity_id)
);

CREATE TABLE teaching_allocation (
    planned_activity_id INT NOT NULL,
    employee_id INT NOT NULL,
    allocation_hours INT NOT NULL,

    PRIMARY KEY (planned_activity_id, employee_id),
    FOREIGN KEY (planned_activity_id) REFERENCES planned_activity(id) ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (employee_id) REFERENCES employee(id) ON UPDATE CASCADE ON DELETE CASCADE
);

-- course layout tables

CREATE TYPE study_period_enum AS ENUM ('P1', 'P2', 'P3', 'P4');
CREATE CAST (text AS study_period_enum) WITH INOUT AS ASSIGNMENT;

CREATE TABLE course_layout (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    course_code VARCHAR(10) NOT NULL UNIQUE,
    course_name VARCHAR(128) NOT NULL
);

CREATE TABLE course_layout_version (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    min_students INT NOT NULL,
    max_students INT,
    ects_credits FLOAT(10) NOT NULL,
    version INT NOT NULL,
    course_layout_id INT NOT NULL,

    FOREIGN KEY (course_layout_id) REFERENCES course_layout(id) ON UPDATE CASCADE,
    UNIQUE (course_layout_id, version),
    CHECK (min_students > 0),
    CHECK (max_students >= min_students)
);

CREATE TABLE course_instance (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    instance_id VARCHAR(16) NOT NULL UNIQUE,
    num_students INT NOT NULL,
    study_period study_period_enum NOT NULL,
    study_year INT NOT NULL,
    course_layout_version_id INT NOT NULL,

    FOREIGN KEY (course_layout_version_id) REFERENCES course_layout_version(id) ON UPDATE CASCADE,
    UNIQUE (course_layout_version_id, study_year, study_period),
    CHECK (study_year > 1970)
);

-- People, employees and departments

CREATE TABLE department (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    department_name VARCHAR(128) NOT NULL UNIQUE,
    manager_employee_id INT NOT NULL
);

CREATE TABLE person (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    personal_number VARCHAR(32) UNIQUE,
    first_name VARCHAR(128) NOT NULL,
    last_name VARCHAR(128) NOT NULL
);

CREATE TABLE job_title (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    job_title_name VARCHAR(128) NOT NULL UNIQUE
);

CREATE TABLE employee (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    employment_id INT NOT NULL UNIQUE,
    department_id INT NOT NULL,
    person_id INT NOT NULL UNIQUE,
    job_title_id INT NOT NULL,
    supervisor_id INT NOT NULL,

    FOREIGN KEY (department_id) REFERENCES department(id) ON UPDATE CASCADE DEFERRABLE INITIALLY DEFERRED,
    FOREIGN KEY (person_id) REFERENCES person(id) ON UPDATE CASCADE,
    FOREIGN KEY (job_title_id) REFERENCES job_title(id) ON UPDATE CASCADE,
    FOREIGN KEY (supervisor_id) REFERENCES employee(id) ON UPDATE CASCADE DEFERRABLE INITIALLY DEFERRED
);

-- Circular dependency:
-- department.manager_employee_id -> employee.id
-- employee.department_id -> department.id

ALTER TABLE department
ADD CONSTRAINT fk_department_manager FOREIGN KEY (manager_employee_id) REFERENCES employee(id) ON UPDATE CASCADE DEFERRABLE INITIALLY DEFERRED;

-- Affiliated properties: address, phone number, skill, salary

CREATE TABLE address (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
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
    address_property VARCHAR(128) NOT NULL,

    PRIMARY KEY (address_id, person_id),
    FOREIGN KEY (address_id) REFERENCES address(id) ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (person_id) REFERENCES person(id) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE phone_number (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    phone_number VARCHAR(32) NOT NULL UNIQUE
);

CREATE TABLE person_phone_number (
    phone_number_id INT NOT NULL,
    person_id INT NOT NULL,
    phone_number_property VARCHAR(128) NOT NULL,

    PRIMARY KEY (phone_number_id, person_id),
    FOREIGN KEY (phone_number_id) REFERENCES phone_number(id) ON UPDATE CASCADE,
    FOREIGN KEY (person_id) REFERENCES person(id) ON UPDATE CASCADE
);

CREATE TABLE skill (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
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
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    salary NUMERIC(12,2) NOT NULL,
    valid_from DATE NOT NULL,
    employee_id INT NOT NULL,

    FOREIGN KEY (employee_id) REFERENCES employee(id) ON UPDATE CASCADE ON DELETE CASCADE,
    UNIQUE (employee_id, valid_from)
);

-- Allocation rule

CREATE TABLE allocation_rule (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    max_courses INT NOT NULL
);

-- Activity and formula

CREATE TABLE activity (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    activity_name VARCHAR(128) NOT NULL UNIQUE
);

CREATE TABLE linear_formula (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    activity_id INT NOT NULL UNIQUE,
    constant_term FLOAT(10) NOT NULL DEFAULT 0,

    FOREIGN KEY (activity_id) REFERENCES activity(id) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE calculation_input (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    name VARCHAR(128) NOT NULL UNIQUE
);

CREATE TABLE coefficient (
    linear_formula_id INT NOT NULL,
    calculation_input_id INT NOT NULL,
    coefficient_number FLOAT(10) NOT NULL,

    PRIMARY KEY (linear_formula_id, calculation_input_id),
    FOREIGN KEY (linear_formula_id) REFERENCES linear_formula(id) ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (calculation_input_id) REFERENCES calculation_input(id) ON UPDATE CASCADE
);

-- Planned activity and allocations

CREATE TABLE planned_activity (
    id INT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    planned_hours INT NOT NULL,
    course_instance_id INT NOT NULL,
    activity_id INT NOT NULL,

    FOREIGN KEY (course_instance_id) REFERENCES course_instance(id) ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (activity_id) REFERENCES activity(id) ON UPDATE CASCADE,
    UNIQUE (course_instance_id, activity_id)
);

CREATE TABLE teaching_allocation (
    planned_activity_id INT NOT NULL,
    employee_id INT NOT NULL,
    allocation_hours INT NOT NULL,

    PRIMARY KEY (planned_activity_id, employee_id),
    FOREIGN KEY (planned_activity_id) REFERENCES planned_activity(id) ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (employee_id) REFERENCES employee(id) ON UPDATE CASCADE ON DELETE CASCADE
);

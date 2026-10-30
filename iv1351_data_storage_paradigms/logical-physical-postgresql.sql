-- course layout tables

CREATE TABLE course_layout (
    course_id INT NOT NULL GENERATED ALWAYS AS IDENTITY PRIMARY KEY ,
    course_code VARCHAR(10) NOT NULL UNIQUE,
    course_name VARCHAR(128) NOT NULL
);

CREATE TABLE course_layout_version (
    course_layout_version_id INT NOT NULL GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    min_students  INT NOT NULL,
    max_students INT NOT NULL,
    ects_credits FLOAT(10) NOT NULL,
    version INT NOT NULL,
    course_id INT NOT NULL,

    FOREIGN KEY (course_id) REFERENCES course_layout(course_id) ON UPDATE CASCADE,
    -- A version number identifies one layout of one course
    UNIQUE (course_id, version),

    CHECK (min_students > 0),
    CHECK (min_students <= max_students),
    CHECK (ects_credits > 0),
    CHECK (version > 0)
);

CREATE TABLE course_instance (
    course_instance_id       INT NOT NULL GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    num_students             INT NOT NULL,
    study_period             VARCHAR(2) NOT NULL,
    study_year               INT NOT NULL,
    course_layout_version_id INT NOT NULL,

    FOREIGN KEY (course_layout_version_id) REFERENCES course_layout_version(course_layout_version_id) ON UPDATE CASCADE,
    -- Many courses run in the same year/period; one course layout version runs at most once per period
    UNIQUE (course_layout_version_id, study_year, study_period),

    CHECK (study_period IN ('P1', 'P2', 'P3', 'P4')),
    CHECK (study_year > 1970),
    CHECK (num_students >= 0)
);

-- People, employees and departments

CREATE TABLE department (
    department_id INT NOT NULL GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    department_name VARCHAR(128) NOT NULL UNIQUE,
    manager_employee_id INT NOT NULL
);

CREATE TABLE person (
    person_id       INT NOT NULL GENERATED ALWAYS AS IDENTITY PRIMARY KEY ,
    personal_number VARCHAR(32) NOT NULL UNIQUE,
    first_name     VARCHAR(128) NOT NULL,
    last_name      VARCHAR(128) NOT NULL,
    phone_number   VARCHAR(32) NOT NULL
);

CREATE TABLE job_title (
    job_title_id   INT NOT NULL GENERATED ALWAYS AS IDENTITY PRIMARY KEY ,
    job_title_name VARCHAR(128) NOT NULL UNIQUE
);

CREATE TABLE employee (
    employee_id INT NOT NULL GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    employment_id INT NOT NULL UNIQUE,
    supervisor_manager_id INT NOT NULL,
    department_id INT NOT NULL,
    -- A person is at most one employee (person 1 -- 0..1 employee)
    person_id INT NOT NULL UNIQUE,
    job_title_id INT NOT NULL,

    -- Deferrable FKs: the first department, its manager and the top-level
    -- supervisor reference each other, so they must be inserted in one
    -- transaction and checked at COMMIT.
    FOREIGN KEY (department_id) REFERENCES department(department_id) ON UPDATE CASCADE
        DEFERRABLE INITIALLY DEFERRED,
    FOREIGN KEY (person_id) REFERENCES person(person_id) ON UPDATE CASCADE,
    FOREIGN KEY (job_title_id) REFERENCES job_title(job_title_id) ON UPDATE CASCADE,
    FOREIGN KEY (supervisor_manager_id) REFERENCES employee(employee_id) ON UPDATE CASCADE
        DEFERRABLE INITIALLY DEFERRED
);

-- Circular dependency:
-- department.manager_employee_id -> employee.employee_id
-- employee.department_id -> department.department_id

ALTER TABLE department
ADD CONSTRAINT fk_department_manager FOREIGN KEY (manager_employee_id) REFERENCES employee(employee_id) ON UPDATE CASCADE
    DEFERRABLE INITIALLY DEFERRED;

-- Affiliated properties: address, skill

CREATE TABLE address (
    address_id INT NOT NULL GENERATED ALWAYS AS IDENTITY PRIMARY KEY ,
    city VARCHAR(128) NOT NULL,
    zip VARCHAR(16) NOT NULL,
    street VARCHAR(128) NOT NULL,
    house_number VARCHAR(16) NOT NULL,
    country VARCHAR(128) NOT NULL
);

CREATE TABLE person_address (
    address_id       INT NOT NULL,
    person_id        INT NOT NULL,
    address_property CHAR(128) NOT NULL,

    PRIMARY KEY (address_id, person_id),
    FOREIGN KEY (address_id) REFERENCES address(address_id) ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (person_id) REFERENCES person(person_id) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE skill (
    skill_id INT NOT NULL GENERATED ALWAYS AS IDENTITY PRIMARY KEY ,
    skill_name VARCHAR(128) NOT NULL UNIQUE
);

CREATE TABLE employee_skill (
    skill_id INT NOT NULL,
    employee_id INT NOT NULL,

    PRIMARY KEY (skill_id, employee_id),
    FOREIGN KEY (skill_id) REFERENCES skill(skill_id) ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (employee_id) REFERENCES employee(employee_id) ON UPDATE CASCADE ON DELETE CASCADE
);

CREATE TABLE employee_salary (
    salary_id   INT NOT NULL GENERATED ALWAYS AS IDENTITY PRIMARY KEY ,
    salary      NUMERIC(12,2) NOT NULL,
    -- PostgreSQL allows at most 6 fractional digits (same as MySQL DATETIME(6))
    valid_from  TIMESTAMP(6) NOT NULL,
    valid_to    TIMESTAMP(6),
    employee_id INT NOT NULL,

    FOREIGN KEY (employee_id) REFERENCES employee(employee_id) ON UPDATE CASCADE ON DELETE CASCADE,
    CHECK (salary >= 0),
    CHECK (valid_from < valid_to)
);

-- Allocation rule
CREATE TABLE allocation_rule (
    rule_id INT NOT NULL GENERATED ALWAYS AS IDENTITY PRIMARY KEY ,
    max_courses INT NOT NULL,
    CHECK (max_courses > 0)
);

-- Activity and formula

CREATE TABLE activity (
    activity_id INT NOT NULL GENERATED ALWAYS AS IDENTITY PRIMARY KEY ,
    activity_name VARCHAR(128) NOT NULL UNIQUE
);

CREATE TABLE linear_formula (
    linear_formula_id INT NOT NULL GENERATED ALWAYS AS IDENTITY PRIMARY KEY ,
    activity_id INT NOT NULL UNIQUE,
    constant_term FLOAT(10) NOT NULL,

    FOREIGN KEY (activity_id) REFERENCES activity(activity_id) ON UPDATE CASCADE
);

CREATE TABLE calculation_input (
    input_id INT NOT NULL GENERATED ALWAYS AS IDENTITY PRIMARY KEY ,
    name VARCHAR(128) NOT NULL UNIQUE
);

CREATE TABLE coefficient (
    linear_formula_id INT NOT NULL,
    input_id INT NOT NULL,
    coefficient_number FLOAT(10) NOT NULL,

    PRIMARY KEY (linear_formula_id, input_id),
    FOREIGN KEY (linear_formula_id) REFERENCES linear_formula(linear_formula_id) ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (input_id) REFERENCES calculation_input(input_id) ON UPDATE CASCADE
);

-- Planned activity and allocations

CREATE TABLE planned_activity (
    planned_activity_id INT NOT NULL GENERATED ALWAYS AS IDENTITY PRIMARY KEY ,
    planned_hours INT NOT NULL,
    course_instance_id INT NOT NULL,
    activity_id INT NOT NULL,

    FOREIGN KEY (course_instance_id) REFERENCES course_instance(course_instance_id) ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (activity_id) REFERENCES activity(activity_id) ON UPDATE CASCADE,
    -- Each activity is planned at most once per course instance
    UNIQUE (course_instance_id, activity_id),
    CHECK (planned_hours >= 0)
);

CREATE TABLE teaching_allocation (
    planned_activity_id INT NOT NULL,
    employee_id INT NOT NULL,
    allocation_hours INT NOT NULL,

    PRIMARY KEY (planned_activity_id, employee_id),
    FOREIGN KEY (planned_activity_id) REFERENCES planned_activity(planned_activity_id) ON UPDATE CASCADE ON DELETE CASCADE,
    FOREIGN KEY (employee_id) REFERENCES employee(employee_id) ON UPDATE CASCADE ON DELETE CASCADE,
    CHECK (allocation_hours >= 0)
);

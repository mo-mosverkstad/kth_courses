-- Planned activity and allocations

DROP TABLE IF EXISTS teaching_allocation CASCADE;
DROP TABLE IF EXISTS planned_activity CASCADE;

-- Activity and formula

DROP TABLE IF EXISTS derived_activity_formula CASCADE;
DROP TABLE IF EXISTS teaching_activity CASCADE;

-- Allocation rule

DROP TABLE IF EXISTS allocation_rule CASCADE;

-- Affiliated properties: address, phone number, skill, salary

DROP TABLE IF EXISTS employee_salary CASCADE;
DROP TABLE IF EXISTS employee_skill CASCADE;
DROP TABLE IF EXISTS skill CASCADE;
DROP TABLE IF EXISTS person_phone_number CASCADE;
DROP TABLE IF EXISTS phone_number CASCADE;
DROP TABLE IF EXISTS person_address CASCADE;
DROP TABLE IF EXISTS address CASCADE;

-- People, employees and departments

DROP TABLE IF EXISTS employee CASCADE;
DROP TABLE IF EXISTS job_title CASCADE;
DROP TABLE IF EXISTS person CASCADE;
DROP TABLE IF EXISTS department CASCADE;

-- course layout tables

DROP TABLE IF EXISTS course_instance CASCADE;
DROP TABLE IF EXISTS academic_period CASCADE;
DROP TABLE IF EXISTS period CASCADE;
DROP TABLE IF EXISTS course_layout CASCADE;
DROP TABLE IF EXISTS course CASCADE;

-- Trigger functions

DROP FUNCTION IF EXISTS validate_4_instances_each_study_period() CASCADE;

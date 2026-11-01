# Hand-off: IV1351 project, Task 1 (logical/physical model)

Last updated 2026-10-31. Only Task 1 is in scope (not Tasks 2 and 3).
Status: models, scripts and trigger are done and consistent. Next step is the LaTeX report.

## Requirement sources

- `requirements.txt` (this folder): project description and all tasks.
- PDFs in `C:\Users\EWANBIN\OneDrive - Ericsson\jobs\RADIO_RTI\MyCCode\Year 2 courses\database\project01`
  (WSL: `/mnt/c/Users/EWANBIN/OneDrive - Ericsson/jobs/RADIO_RTI/MyCCode/Year 2 courses/database/project01`):
  `Project_ IV1351 HT26 ...pdf`, `project-task-1_ IV1351 HT26 ...pdf`,
  `assessment-criteria-seminar1.pdf`, `seminar1-tips-and-tricks.pdf`.
  Extract text with `pdftotext -layout` in WSL (poppler-utils is installed).
- Course examples: `conceptual_model_course.png`, `logical_physical_course_given.png`, `log-phys-mod.pdf`.
- Report template (not yet in the workspace): `iv1351-report-template_new.tex`, linked from the Canvas Project page.

## Files in this folder

| File | Purpose / state |
|---|---|
| `conceptual.svg` | Conceptual model (Astah export). Reviewed 2026-10-31 23:06, OK |
| `logical-physical.svg` | Logical/physical model (Astah export). Reviewed 22:59, in sync with SQL |
| `logical-physical-postgresql.sql` | Create script, PostgreSQL (21 tables) |
| `logical-physical-mysql.sql` | Same schema for MySQL 8.0.16+ |
| `db-insertion-postgresql.sql` | Insert script, PostgreSQL (BEGIN/COMMIT around department bootstrap) |
| `db-insertion-mysql.sql` | Insert script, MySQL (FOREIGN_KEY_CHECKS = 0/1 around department bootstrap) |
| `trigger-postgresql.sql` | User's max-4 trigger, verified correct |
| `trigger-postgresql-ref.sql` | Reference version of the same trigger |
| `clean-postgresql.sql` | Drops all 21 tables and the trigger function (idempotent) |
| `build.bash` | clean, create, trigger, insert against `course_database` (PostgreSQL) |
| `output.txt`, `postgres_help.txt`, `requirement_check_discussion.txt` | User's own notes/scratch files |

The create scripts contain no `CREATE DATABASE`; the user reverted that. They run inside an existing `course_database`.

## Schema summary (21 tables)

- Course: `course`, `course_layout` (versioned: `version`, `UNIQUE(course_id, version)`, `hp NUMERIC(4,1)`,
  `max_students` nullable = no limit, `CHECK(min_students > 0)`, `CHECK(max_students >= min_students)`),
  `period` (P1-P4 lookup), `academic_period` (year + period + NOT NULL start/end dates),
  `course_instance` (`instance_id VARCHAR(16) UNIQUE`, `UNIQUE(course_layout_id, academic_period_id)`).
- People: `department` (`manager_employee_id NOT NULL`, deferred FK in PostgreSQL), `person`
  (`personal_number` nullable UNIQUE), `job_title`, `employee` (`supervisor_id` nullable = top employee),
  `address`, `person_address`, `phone_number`, `person_phone_number` (both junctions ON DELETE CASCADE),
  `skill`, `employee_skill`, `employee_salary` (only `valid_from`, `UNIQUE(employee_id, valid_from)`).
- Rules/activities: `allocation_rule (max_courses)`, `teaching_activity (multiplication_factor)`,
  `derived_activity_formula (teaching_activity_id UNIQUE, base_hours, hours_per_student, hours_per_hp)`,
  `planned_activity` (`planned_hours` nullable for derived exam/admin,
  `UNIQUE(course_instance_id, teaching_activity_id)`), `teaching_allocation (allocation_hours)` raw hours.
- Conventions: PK `id`, FK `<table>_id` or role name; ON UPDATE CASCADE everywhere; delete restricted unless a note says CASCADE.
  Script style: single spaces, no explanatory comments, only section comments.

## Insert data

- 18 courses, 18 layouts, 4 periods, 12 academic periods (2023-2025, quarters Jan-Dec), 44 instances
  (instance_id pattern `year-5` + 3-digit course id + period number, e.g. `2025-50022` = IV1351 P2).
- 32 persons/addresses/phones (user's sample data, unchanged except `country = 'Sweden'` added and numbers quoted),
  4 departments, 20 employees (employment_id 500001-500020, 500001 has no supervisor), 7 KTH job titles,
  9 skills, 25 salaries (raises on 2025-01-01), 7 teaching activities, 2 formulas, max_courses = 4.
- 25 planned activities, 38 allocations. Focus on IV1351 (`2025-50022`, `2024-50022`) and IX1500
  (`2025-50011`, `2024-50011`), using the project's Table 3 hours. Employee 500005 has exactly 4 instances in 2025 P2.
- FKs are looked up by business values, never by hardcoded ids.

## Trigger (max-4 rule)

`trigger_4_instances_each_study_period` BEFORE INSERT OR UPDATE on `teaching_allocation`: finds the new row's
instance and academic period, counts the teacher's other instances in that period, raises if count >= max_courses.
Verified: 5th instance rejected, extra activity in an existing instance accepted, UPDATE moving an allocation
rejected, other period accepted. MySQL has no trigger (only PostgreSQL enforces the rule).

## Open items

1. `logical-physical.svg`: the max-4 note should mention the trigger (not yet checked after 22:59).
2. Optional: in `conceptual.svg`, `employee.supervisor/manager` and `department.manager` are attributes;
   either draw relations or explain the conversion in the report.
3. Drop the stray table once: `sudo -u postgres psql -d course_database -c 'DROP TABLE current_value;'`
   (leftover from an earlier trigger attempt; a clean build should have 21 tables).
4. Optional: add `-v ON_ERROR_STOP=1` to each psql line in `build.bash`.
5. Decide whether to submit MySQL scripts too (no trigger there) or only PostgreSQL.
6. Git repo: make it accessible, leave out scratch files and this HANDOFF.md.
7. Write the report (Method, Result, Discussion).

## Report notes

- Method: tools (Astah, PostgreSQL 16 in WSL, MySQL 8.0), steps from conceptual to logical/physical model,
  how the database was verified (scratch DB, run scripts with ON_ERROR_STOP, probe inserts for each constraint).
- Result: conceptual diagram first, then logical-physical, short explanation, git link.
- Discussion (must be extensive for higher grade), both required topics plus criteria:
  - All data in the DB: max_courses, factors, formula constants, period dates; pros/cons vs. application code.
  - Multiple versions: course_layout versions, salary history without valid_to (no overlaps possible, gaps not
    representable); course_name, factors and formulas are not versioned.
  - Surrogate `id` on weak entities plus UNIQUE natural keys; `id` naming loses NATURAL JOIN.
  - Derived exam/admin hours computed, not stored; formula table has fixed inputs (students, HP).
  - Free-text `address_property` / `phone_number_property` (criteria prefer lookup tables).
  - Circular department/manager FK (deferred in PostgreSQL); nullable `personal_number` and `supervisor_id`.
  - Trigger concurrency (two sessions could both pass the check; relevant for Task 3 with SELECT FOR UPDATE).

## Environment and working tips

- WSL distro `Ubuntu`: PostgreSQL 16 (cluster `main`, port 5432), MySQL 8.0.46, ImageMagick, poppler-utils.
  After a reboot: `sudo service postgresql start`, `sudo service mysql start`.
- No DB role for WSL user `ewanbin`, so `psql -U postgres` fails with peer authentication.
  Use `sudo -u postgres psql -d course_database ...` or create a role:
  `sudo -u postgres createuser --superuser ewanbin`. The user knows the sudo password (not stored here).
- Run scripts with `< file` or `-f file` from this folder; add `-v ON_ERROR_STOP=1`; use `PAGER=cat` in automation.
- Test in a scratch DB (`task1_review`), never in `course_database` unless asked. Write multi-line shell scripts to
  `%TEMP%`, strip CR with `tr -d '\r'`, run them in WSL. Files in this folder use CRLF line endings.
- Viewing diagrams: SVG text is glyph paths. Render with headless Edge
  (`msedge --headless=new --screenshot=... --window-size=WxH file:///...svg`), crop with `convert ... -crop 3x2@`
  in WSL. ImageMagick alone renders these SVGs blank.
- User preferences: point out errors in the user's own code before fixing it when asked to review; keep SQL
  scripts free of explanatory comments; keep inserts short (about 10-16 rows each) with blank lines between tables.

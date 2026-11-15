-- Teacher load per period (5/day), read from teacher_period_load_view

SELECT
    teacher_period_load_view.employment_id,
    teacher_period_load_view.teacher_name,
    teacher_period_load_view.academic_year,
    teacher_period_load_view.period_number,
    teacher_period_load_view.number_of_courses,
    teacher_period_load_view.total_hours
FROM teacher_period_load_view

-- Parameter part begin
WHERE teacher_period_load_view.academic_year = 2025
-- Parameter part end

ORDER BY
    teacher_period_load_view.academic_year DESC,
    teacher_period_load_view.period_number,
    teacher_period_load_view.teacher_name;

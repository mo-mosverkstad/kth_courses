package se.kth.iv1351.coursedb.dto;

import java.math.BigDecimal;

/**
 * An immutable read-only view of one course instance, together with the course and the
 * academic period it belongs to. The data is collected by joining the tables
 * <code>course</code>, <code>course_layout</code>, <code>course_instance</code>,
 * <code>academic_period</code> and <code>period</code>.
 *
 * @param instanceId   The business id of the course instance, for example
 *                     <code>2026-50000022</code>.
 * @param courseCode   The course code, for example <code>IV1351</code>.
 * @param courseName   The name of the course.
 * @param periodName   The name of the period, for example <code>P2</code>.
 * @param academicYear The academic year of the course instance.
 * @param hp           The number of credits of the course layout.
 * @param numStudents  The number of registered students.
 */
public record CourseInstanceDTO(String instanceId, String courseCode, String courseName,
                                String periodName, int academicYear, BigDecimal hp,
                                int numStudents) {
}

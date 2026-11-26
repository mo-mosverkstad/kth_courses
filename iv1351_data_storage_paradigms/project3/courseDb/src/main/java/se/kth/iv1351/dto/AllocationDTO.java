package se.kth.iv1351.dto;

/**
 * An immutable read-only view of one teaching allocation, which connects one teacher with
 * one planned activity of one course instance. The data is collected by joining the tables
 * <code>teaching_allocation</code>, <code>planned_activity</code>,
 * <code>teaching_activity</code>, <code>course_instance</code>, <code>employee</code> and
 * <code>person</code>.
 *
 * @param employmentId    The business id of the employment of the allocated teacher.
 * @param teacherName     The full name of the allocated teacher.
 * @param instanceId      The business id of the course instance.
 * @param courseCode      The course code of the course instance.
 * @param activityName    The name of the allocated teaching activity.
 * @param allocationHours The allocated raw hours, without the multiplication factor.
 */
public record AllocationDTO(int employmentId, String teacherName, String instanceId,
                            String courseCode, String activityName, int allocationHours) {
}

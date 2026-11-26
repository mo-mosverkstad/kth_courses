package se.kth.iv1351.dto;

/**
 * An immutable read-only view of one planned activity of one course instance. The data is
 * collected by joining the tables <code>planned_activity</code>,
 * <code>teaching_activity</code> and <code>course_instance</code>.
 *
 * @param plannedActivityId The database id of the planned activity, which is needed in
 *                          order to create and delete allocations.
 * @param instanceId        The business id of the course instance the planned activity
 *                          belongs to.
 * @param activityName      The name of the teaching activity that is planned.
 * @param plannedHours      The planned raw hours, without the multiplication factor.
 */
public record PlannedActivityDTO(int plannedActivityId, String instanceId,
                                 String activityName, int plannedHours) {
}

package se.kth.iv1351.coursedb.dto;

import java.math.BigDecimal;

/**
 * An immutable read-only view of one teaching activity, read from the table
 * <code>teaching_activity</code>.
 *
 * @param activityName         The name of the teaching activity, for example
 *                             <code>Lecture</code>.
 * @param multiplicationFactor The factor that raw hours are multiplied with, in order to
 *                             get the hours that the teacher is paid for.
 */
public record TeachingActivityDTO(String activityName, BigDecimal multiplicationFactor) {
}

package se.kth.iv1351.dto;

import java.math.BigDecimal;

/**
 * An immutable read-only view of the teaching cost of one course instance. Unlike the
 * other DTOs, this one is not read from the database. It is created by the model, from
 * hours read by the integration layer and an average salary, since the cost is calculated
 * by a business rule and must therefore not be calculated in the integration layer.
 *
 * @param courseCode      The course code of the course instance.
 * @param instanceId      The business id of the course instance.
 * @param periodName      The name of the period of the course instance.
 * @param plannedCostKSEK The cost of the planned teaching hours, in thousands of SEK.
 * @param actualCostKSEK  The cost of the hours that are actually allocated to teachers, in
 *                        thousands of SEK.
 */
public record TeachingCostDTO(String courseCode, String instanceId, String periodName,
                              BigDecimal plannedCostKSEK, BigDecimal actualCostKSEK) {
}

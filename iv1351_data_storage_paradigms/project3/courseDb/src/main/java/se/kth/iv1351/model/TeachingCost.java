package se.kth.iv1351.model;

import java.math.BigDecimal;

import se.kth.iv1351.dto.CourseInstanceDTO;
import se.kth.iv1351.dto.TeachingCostDTO;

/**
 * The teaching cost of one course instance, both as planned and as actually allocated.
 * This class owns the rule for how an amount of teaching hours is turned into a cost.
 */
public class TeachingCost {
    /**
     * The number of working hours in one month, used to turn a monthly salary into an
     * hourly cost.
     */
    private static final int WORKING_HOURS_PER_MONTH = 160;

    private final CourseInstanceDTO courseInstance;
    private final BigDecimal plannedHours;
    private final BigDecimal allocatedHours;
    private final Amount averageMonthlySalary;

    /**
     * Creates a new instance for the specified course instance.
     *
     * @param courseInstance       The course instance the cost is calculated for.
     * @param plannedHours         The planned hours, including multiplication factors.
     * @param allocatedHours       The hours allocated to teachers, including
     *                             multiplication factors.
     * @param averageMonthlySalary The average monthly salary of a teacher.
     */
    public TeachingCost(CourseInstanceDTO courseInstance, BigDecimal plannedHours,
                        BigDecimal allocatedHours, Amount averageMonthlySalary) {
        this.courseInstance = courseInstance;
        this.plannedHours = plannedHours;
        this.allocatedHours = allocatedHours;
        this.averageMonthlySalary = averageMonthlySalary;
    }

    /**
     * @return The cost of the planned teaching hours.
     */
    public Amount getPlannedCost() {
        return costOf(plannedHours);
    }

    /**
     * @return The cost of the hours that are actually allocated to teachers.
     */
    public Amount getActualCost() {
        return costOf(allocatedHours);
    }

    /**
     * @return The planned hours the cost is based on.
     */
    public BigDecimal getPlannedHours() {
        return plannedHours;
    }

    /**
     * @return The allocated hours the cost is based on.
     */
    public BigDecimal getAllocatedHours() {
        return allocatedHours;
    }

    /**
     * @return A read-only view of the calculated cost, with the costs in thousands of SEK.
     */
    public TeachingCostDTO toDTO() {
        return new TeachingCostDTO(courseInstance.courseCode(),
                                   courseInstance.instanceId(),
                                   courseInstance.periodName(),
                                   getPlannedCost().inThousands(),
                                   getActualCost().inThousands());
    }

    /**
     * Calculates the cost of the specified number of teaching hours, as the hourly cost
     * of a teacher multiplied with the number of hours.
     *
     * @param hours The number of teaching hours.
     * @return The cost of the specified hours.
     */
    private Amount costOf(BigDecimal hours) {
        Amount hourlyCost = averageMonthlySalary.divide(WORKING_HOURS_PER_MONTH);
        return hourlyCost.multiply(hours);
    }

    /**
     * @return A string representation of all fields in this object.
     */
    @Override
    public String toString() {
        return toDTO().toString();
    }
}

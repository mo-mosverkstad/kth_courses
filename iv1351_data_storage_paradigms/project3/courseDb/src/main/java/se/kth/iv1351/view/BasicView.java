package se.kth.iv1351.view;

import java.math.BigDecimal;
import java.util.List;

import se.kth.iv1351.controller.CourseDBController;
import se.kth.iv1351.dto.AllocationDTO;
import se.kth.iv1351.model.CourseException;
import se.kth.iv1351.model.RejectedException;

/** Minimal command-line view for displaying a course instance's teaching cost. */
public class BasicView implements View {
    private final CourseDBController controller;
    private final String instanceId;

    public BasicView(CourseDBController controller, String instanceId) {
        this.controller = controller;
        this.instanceId = instanceId;
    }

    @Override
    public void start() {
        controller.test();
        try {
            System.out.println("--- Calculating teaching cost ---");
            System.out.println(controller.calculateTeachingCost(instanceId));
            System.out.println();

            System.out.println("--- Add 100 more students ---");
            controller.addRegisteredStudents(instanceId, 100);
            System.out.println("--- Calculating teaching cost again! ---");
            System.out.println(controller.calculateTeachingCost(instanceId));
            System.out.println();

            System.out.println("--- Allocate/deallocate teacher ---");
            int employmentId = 500018;
            String activityName = "Administration";
            int allocationHours = 30;

            System.out.println("--- Allocate Mallory Terrell (" + employmentId + ") to " + activityName + " for " + allocationHours + " hours ---");
            System.out.println(controller.allocateTeacher(employmentId, instanceId, activityName, allocationHours));
            System.out.println();

            System.out.println("--- Deallocate Mallory Terrell from " + activityName + " ---");
            System.out.println(controller.deallocateTeacher(employmentId, instanceId, activityName));
            System.out.println();

            System.out.println("--- Read allocations for " + instanceId + " ---");
            System.out.println(controller.getAllocations(instanceId));
            System.out.println();

            String newActivityName = "Exercise";
            BigDecimal multiplicationFactor = new BigDecimal("2.00");
            int plannedHours = 30;
            int newAllocationHours = 15;
            System.out.println("--- Add " + newActivityName + " (factor " + multiplicationFactor + ", planned hours " + plannedHours + ") and allocate Mallory Terrell (" + employmentId + ") for " + newAllocationHours + " hours ---");
            System.out.println(controller.addTeachingActivity(newActivityName, multiplicationFactor, instanceId, plannedHours, employmentId, newAllocationHours));
            System.out.println();

        } catch (RejectedException | CourseException exception) {
            System.err.println(exception.getMessage());
            exception.printStackTrace(System.err);
        }
    }

    private void printAllocations(List<AllocationDTO> allocations) {
        if (allocations.isEmpty()) {
            System.out.println("No teaching allocations.");
            return;
        }
        allocations.forEach(allocation -> System.out.printf(
                "%s (%d) - %s, %s, %d hours%n",
                allocation.teacherName(), allocation.employmentId(), allocation.instanceId(),
                allocation.activityName(), allocation.allocationHours()));
    }
}

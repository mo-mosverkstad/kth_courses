package se.kth.iv1351.view;

import se.kth.iv1351.controller.CourseDBController;
import se.kth.iv1351.dto.TeachingCostDTO;
import se.kth.iv1351.model.CourseException;

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
            printCost(controller.calculateTeachingCost(instanceId));
        } catch (CourseException exception) {
            System.err.println(exception.getMessage());
            exception.printStackTrace(System.err);
        }
    }

    private void printCost(TeachingCostDTO cost) {
        System.out.printf("%-12s %-18s %-8s %24s %22s%n", "Course Code",
                          "Course Instance", "Period", "Planned Cost (KSEK)",
                          "Actual Cost (KSEK)");
        System.out.printf("%-12s %-18s %-8s %18s %17s%n", cost.courseCode(),
                          cost.instanceId(), cost.periodName(), cost.plannedCostKSEK(),
                          cost.actualCostKSEK());
    }
}

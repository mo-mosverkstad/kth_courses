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
            System.out.println("--- Calculating teaching cost ---");
            System.out.println(controller.calculateTeachingCost(instanceId));
            System.out.println();

            System.out.println("--- Add 100 more students ---");
            controller.addRegisteredStudents(instanceId, 100);
            System.out.println("--- Calculating teaching cost again! ---");
            System.out.println(controller.calculateTeachingCost(instanceId));
            System.out.println();
        } catch (CourseException exception) {
            System.err.println(exception.getMessage());
            exception.printStackTrace(System.err);
        }
    }
}

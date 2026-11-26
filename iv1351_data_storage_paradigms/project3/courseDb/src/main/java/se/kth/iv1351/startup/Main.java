package se.kth.iv1351.startup;

import se.kth.iv1351.controller.CourseDBController;
import se.kth.iv1351.integration.DatabaseConnectionException;
import se.kth.iv1351.view.BasicView;

public class Main {
    private static final String DEFAULT_INSTANCE_ID = "2026-50000011";

    public static void main(String[] args) {
        try{
            String instanceId = args.length > 0 ? args[0] : DEFAULT_INSTANCE_ID;
            new BasicView(new CourseDBController(), instanceId).start();
        }
        catch (RuntimeException exception){
            System.out.println("--- Startup errors ---");
            exception.printStackTrace();
            System.out.println("--- ---");
        }
    }
}

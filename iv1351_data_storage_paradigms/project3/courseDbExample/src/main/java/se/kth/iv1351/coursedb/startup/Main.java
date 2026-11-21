package se.kth.iv1351.coursedb.startup;

import se.kth.iv1351.coursedb.controller.CourseController;
import se.kth.iv1351.coursedb.integration.CourseDBException;
import se.kth.iv1351.coursedb.view.BlockingInterpreter;

/**
 * Starts the course database client.
 */
public class Main {
    /**
     * Connects to the course database and starts the command interpreter.
     *
     * @param args There are no command line parameters.
     */
    public static void main(String[] args) {
        try {
            new BlockingInterpreter(new CourseController()).handleCmds();
        } catch (CourseDBException exception) {
            System.out.println("Could not connect to the course database.");
            System.out.println(exception.getMessage());
        }
    }
}

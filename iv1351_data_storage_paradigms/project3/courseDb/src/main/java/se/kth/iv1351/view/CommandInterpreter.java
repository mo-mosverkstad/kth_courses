package se.kth.iv1351.view;

import java.math.BigDecimal;
import java.util.List;
import java.util.Scanner;

import se.kth.iv1351.controller.CourseDBController;
import se.kth.iv1351.dto.AllocationDTO;
import se.kth.iv1351.dto.TeachingCostDTO;
import se.kth.iv1351.model.CourseException;
import se.kth.iv1351.model.RejectedException;

public class CommandInterpreter implements View {
    private static final String PROMPT = "> ";
    private final Scanner inputScanner = new Scanner(System.in);
    private CourseDBController controller;
    private boolean running = true;

    /**
     * Creates a new instance that will use the specified controller for all operations
     * 
     * @param controller The controller used by this instance
     */
    public CommandInterpreter(CourseDBController controller) {
        this.controller = controller;
    }

    public void start(){
        while (running){
            handleCmds();
        }
    }

    /**
     * Stops the command interpreter
     */
    public void stop() {
        running = false;
    }

    /**
     * Interprets and performs user commands. This method will not return until the
     * UI has been stopped. The UI is stopped either when the user gives the
     * "quit" command, or when the method <code>stop()</code> is called.
     */
    public void handleCmds() {
        try {
            CommandLine cmdLine = new CommandLine(readNextLine());
            List<String> arguments = cmdLine.getArguments();
            switch (CommandType.fromString(cmdLine.getCommand())) {
                case HELP:
                    if (hasArguments(arguments, 0)){
                        for (CommandType command : CommandType.values()) {
                            if (command == CommandType.ILLEGAL_COMMAND) {
                                continue;
                            }
                            System.out.println(command.getCommand());
                        }
                    }
                    break;
                case ECHO:
                    System.out.println(arguments);
                    break;
                case SHOW_TEACHING_COST:
                    if (hasArguments(arguments, 1)) {
                        printCost(controller.calculateTeachingCost(arguments.get(0)));
                    }
                    break;
                case ADDSTUDENTS:
                    if (hasArguments(arguments, 2)) {
                        controller.addRegisteredStudents(arguments.get(0),
                                Integer.parseInt(arguments.get(1)));
                        System.out.println("registered students updated");
                    }
                    break;
                case ALLOCATE:
                    if (hasArguments(arguments, 4)) {
                        printAllocations(controller.allocateTeacher(
                                Integer.parseInt(arguments.get(0)), arguments.get(1),
                                arguments.get(2), Integer.parseInt(arguments.get(3))));
                    }
                    break;
                case DEALLOCATE:
                    if (hasArguments(arguments, 3)) {
                        printAllocations(controller.deallocateTeacher(
                                Integer.parseInt(arguments.get(0)), arguments.get(1),
                                arguments.get(2)));
                    }
                    break;
                case NEWACTIVITY:
                    if (hasArguments(arguments, 6)) {
                        printAllocations(controller.addTeachingActivity(arguments.get(0),
                                new BigDecimal(arguments.get(1)), arguments.get(2),
                                Integer.parseInt(arguments.get(3)),
                                Integer.parseInt(arguments.get(4)),
                                Integer.parseInt(arguments.get(5))));
                    }
                    break;
                case LIST:
                    if (hasArguments(arguments, 1)) {
                        printAllocations(controller.getAllocations(arguments.get(0)));
                    }
                    break;
                case QUIT:
                    stop();
                    break;
                
                default:
                    System.out.println("illegal command, type help for a list");
            }
        } catch (RejectedException rejected) {
            System.out.println("refused: " + rejected.getMessage());
        } catch (NumberFormatException | IndexOutOfBoundsException wrongParameters) {
            System.out.println("wrong parameters, type help for a list");
        } catch (CourseException failure) {
            System.out.println("operation failed");
            System.out.println(failure.getMessage());
        } catch (Exception e) {
            System.out.println("Operation failed");
            System.out.println(e.getMessage());
        }
    }

    private boolean hasArguments(List<String> arguments, int requiredCount) {
        if (arguments.size() == requiredCount) {
            return true;
        }
        System.out.println("wrong number of parameters, type help for a list");
        return false;
    }

    private void printCost(TeachingCostDTO cost) {
        System.out.printf("%-10s %-16s %-6s %14s %14s%n", "Course", "Course Instance",
                "Period", "Planned (KSEK)", "Actual (KSEK)");
        System.out.printf("%-10s %-16s %-6s %14s %14s%n", cost.courseCode(),
                cost.instanceId(), cost.periodName(), cost.plannedCostKSEK(),
                cost.actualCostKSEK());
    }

    private void printAllocations(List<AllocationDTO> allocations) {
        if (allocations.isEmpty()) {
            System.out.println("no allocations");
            return;
        }
        System.out.printf("%-8s %-16s %-15s %-14s %-24s %6s%n", "Course",
                "Course Instance", "Activity", "Employment Id", "Teacher", "Hours");
        for (AllocationDTO allocation : allocations) {
            System.out.printf("%-8s %-16s %-15s %-14d %-24s %6d%n",
                    allocation.courseCode(), allocation.instanceId(),
                    allocation.activityName(), allocation.employmentId(),
                    allocation.teacherName(), allocation.allocationHours());
        }
    }

    private String readNextLine() {
        System.out.print(PROMPT);
        return inputScanner.nextLine();
    }


}

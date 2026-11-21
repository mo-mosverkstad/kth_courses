package se.kth.iv1351.coursedb.view;

import java.math.BigDecimal;
import java.util.List;
import java.util.Scanner;

import se.kth.iv1351.coursedb.controller.CourseController;
import se.kth.iv1351.coursedb.dto.AllocationDTO;
import se.kth.iv1351.coursedb.dto.TeachingCostDTO;
import se.kth.iv1351.coursedb.model.RejectedException;

/**
 * Reads and interprets user commands. This command interpreter blocks when waiting for
 * user input. The interpreter contains no business rules, it only reads input, calls the
 * controller and prints the result.
 */
public class BlockingInterpreter {
    private static final String PROMPT = "> ";

    private final Scanner console = new Scanner(System.in);
    private final CourseController contr;
    private boolean keepReceivingCmds = false;

    /**
     * Creates a new instance that uses the specified controller.
     *
     * @param contr The controller to use.
     */
    public BlockingInterpreter(CourseController contr) {
        this.contr = contr;
    }

    /**
     * Stops the command interpreter.
     */
    public void stop() {
        keepReceivingCmds = false;
    }

    /**
     * Interprets and performs user commands. This method blocks until the user enters the
     * command <code>quit</code>, or the input ends.
     */
    public void handleCmds() {
        keepReceivingCmds = true;
        while (keepReceivingCmds) {
            try {
                CmdLine cmdLine = new CmdLine(readNextLine());
                switch (cmdLine.getCmd()) {
                    case HELP:
                        printHelp();
                        break;
                    case QUIT:
                        keepReceivingCmds = false;
                        break;
                    case COST:
                        if (hasParameters(cmdLine, 1)) {
                            printCost(contr.calculateTeachingCost(cmdLine.getParameter(0)));
                        }
                        break;
                    case ADDSTUDENTS:
                        if (hasParameters(cmdLine, 2)) {
                            printCost(contr.addRegisteredStudents(
                                    cmdLine.getParameter(0),
                                    Integer.parseInt(cmdLine.getParameter(1))));
                        }
                        break;
                    case ALLOCATE:
                        if (hasParameters(cmdLine, 4)) {
                            printAllocations(contr.allocateTeacher(
                                    Integer.parseInt(cmdLine.getParameter(0)),
                                    cmdLine.getParameter(1),
                                    cmdLine.getParameter(2),
                                    Integer.parseInt(cmdLine.getParameter(3))));
                        }
                        break;
                    case DEALLOCATE:
                        if (hasParameters(cmdLine, 3)) {
                            printAllocations(contr.deallocateTeacher(
                                    Integer.parseInt(cmdLine.getParameter(0)),
                                    cmdLine.getParameter(1),
                                    cmdLine.getParameter(2)));
                        }
                        break;
                    case NEWACTIVITY:
                        if (hasParameters(cmdLine, 6)) {
                            printAllocations(contr.addTeachingActivity(
                                    cmdLine.getParameter(0),
                                    new BigDecimal(cmdLine.getParameter(1)),
                                    cmdLine.getParameter(2),
                                    Integer.parseInt(cmdLine.getParameter(3)),
                                    Integer.parseInt(cmdLine.getParameter(4)),
                                    Integer.parseInt(cmdLine.getParameter(5))));
                        }
                        break;
                    case LIST:
                        if (hasParameters(cmdLine, 1)) {
                            printAllocations(contr.getAllocations(cmdLine.getParameter(0)));
                        }
                        break;
                    default:
                        System.out.println("illegal command, type help for a list");
                }
            } catch (RejectedException rejected) {
                System.out.println("refused: " + rejected.getMessage());
            } catch (NumberFormatException | NullPointerException wrongParameters) {
                System.out.println("wrong parameters, type help for a list");
            } catch (Exception failure) {
                System.out.println("operation failed");
                System.out.println(failure.getMessage());
            }
        }
    }

    private String readNextLine() {
        System.out.print(PROMPT);
        return console.nextLine();
    }

    private boolean hasParameters(CmdLine cmdLine, int requiredNumberOfParameters) {
        if (cmdLine.getNumberOfParameters() >= requiredNumberOfParameters) {
            return true;
        }
        System.out.println("the command " + cmdLine.getCmd().toString().toLowerCase()
                           + " needs " + requiredNumberOfParameters
                           + " parameters, type help for a list");
        return false;
    }

    private void printHelp() {
        System.out.println("cost <course instance>");
        System.out.println("addstudents <course instance> <number of students>");
        System.out.println("allocate <employment id> <course instance> <activity> <hours>");
        System.out.println("deallocate <employment id> <course instance> <activity>");
        System.out.println("newactivity <activity> <factor> <course instance> "
                           + "<planned hours> <employment id> <allocated hours>");
        System.out.println("list <course instance>");
        System.out.println("help");
        System.out.println("quit");
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
        System.out.printf("%-8s %-16s %-15s %-14s %-24s %6s%n", "Course", "Course Instance",
                          "Activity", "Employment Id", "Teacher", "Hours");
        for (AllocationDTO allocation : allocations) {
            System.out.printf("%-8s %-16s %-15s %-14d %-24s %6d%n", allocation.courseCode(),
                              allocation.instanceId(), allocation.activityName(),
                              allocation.employmentId(), allocation.teacherName(),
                              allocation.allocationHours());
        }
    }
}

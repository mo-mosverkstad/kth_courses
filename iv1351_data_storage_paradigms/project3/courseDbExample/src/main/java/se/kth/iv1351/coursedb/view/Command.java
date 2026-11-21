package se.kth.iv1351.coursedb.view;

/**
 * Defines all commands that can be performed by a user of the application.
 */
public enum Command {
    /**
     * Shows the planned and the actual teaching cost of a course instance.
     */
    COST,
    /**
     * Adds registered students to a course instance and shows the cost afterwards.
     */
    ADDSTUDENTS,
    /**
     * Allocates a teacher to a teaching activity of a course instance.
     */
    ALLOCATE,
    /**
     * Removes the allocation of a teacher to a teaching activity of a course instance.
     */
    DEALLOCATE,
    /**
     * Creates a teaching activity, plans it in a course instance and allocates a teacher.
     */
    NEWACTIVITY,
    /**
     * Lists all allocations of a course instance.
     */
    LIST,
    /**
     * Lists all commands.
     */
    HELP,
    /**
     * Leaves the application.
     */
    QUIT,
    /**
     * None of the valid commands above was specified.
     */
    ILLEGAL_COMMAND
}

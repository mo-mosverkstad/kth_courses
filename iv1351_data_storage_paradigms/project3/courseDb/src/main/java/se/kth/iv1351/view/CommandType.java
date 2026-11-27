package se.kth.iv1351.view;

public enum CommandType {
    /**
     * Shows the planned and the actual teaching cost of a course instance.
     */
    SHOW_TEACHING_COST("cost"),

    /**
     * Adds registered students to a course instance and shows the cost afterwards.
     */
    ADDSTUDENTS("addstudents"),

    /**
     * Allocates a teacher to a teaching activity of a course instance.
     */
    ALLOCATE("alloc"),

    /**
     * Removes the allocation of a teacher to a teaching activity of a course instance.
     */
    DEALLOCATE("dealloc"),

    /**
     * Creates a teaching activity, plans it in a course instance and allocates a teacher.
     */
    NEWACTIVITY("newactivity"),

    /**
     * Lists all allocations of a course instance.
     */
    LIST("listalloc"),

    /**
     * Lists all commands.
     */
    HELP("help"),

    /**
     * Leaves the application.
     */
    QUIT("quit"),

    /**
     * None of the valid commands above was specified.
     */
    ILLEGAL_COMMAND("illegalcommand");

    private final String command;

    CommandType(String command) {
        this.command = command;
    }

    public String getCommand() {
        return command;
    }

    public static CommandType fromString(String command) {
        for (CommandType type : values()) {
            if (type.command.equalsIgnoreCase(command)) {
                return type;
            }
        }
        return ILLEGAL_COMMAND;
    }
}

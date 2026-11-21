package se.kth.iv1351.coursedb.view;

/**
 * One line of user input, interpreted as a command followed by parameters. The command is
 * the first word of the line, the parameters are the remaining words.
 */
class CmdLine {
    private static final String PARAM_DELIMETER = " ";

    private final String enteredLine;
    private Command cmd;
    private String[] params;

    /**
     * Creates a new instance representing the specified line.
     *
     * @param enteredLine The line that was entered by the user.
     */
    CmdLine(String enteredLine) {
        this.enteredLine = enteredLine;
        parseCmd(enteredLine);
        parseParams(enteredLine);
    }

    /**
     * @return The command of this line.
     */
    Command getCmd() {
        return cmd;
    }

    /**
     * Gets the parameter with the specified index, where the first parameter has index
     * zero.
     *
     * @param index The index of the parameter.
     * @return The parameter, or <code>null</code> if there is no parameter with the
     *         specified index.
     */
    String getParameter(int index) {
        if (params == null || index < 0 || index >= params.length) {
            return null;
        }
        return params[index];
    }

    /**
     * @return The number of parameters of this line.
     */
    int getNumberOfParameters() {
        return params == null ? 0 : params.length;
    }

    /**
     * @return The entire line that was entered by the user.
     */
    String getEnteredLine() {
        return enteredLine;
    }

    private void parseCmd(String enteredLine) {
        int cmdNameIndex = 0;
        String[] enteredWords = enteredLine.strip().split(PARAM_DELIMETER);
        try {
            cmd = Command.valueOf(enteredWords[cmdNameIndex].strip().toUpperCase());
        } catch (IllegalArgumentException | ArrayIndexOutOfBoundsException exception) {
            cmd = Command.ILLEGAL_COMMAND;
        }
    }

    private void parseParams(String enteredLine) {
        String[] enteredWords = enteredLine.strip().split(PARAM_DELIMETER);
        int noOfParams = enteredWords.length - 1;
        if (noOfParams <= 0) {
            params = new String[0];
            return;
        }
        params = new String[noOfParams];
        for (int i = 0; i < noOfParams; i++) {
            params[i] = enteredWords[i + 1].strip();
        }
    }
}

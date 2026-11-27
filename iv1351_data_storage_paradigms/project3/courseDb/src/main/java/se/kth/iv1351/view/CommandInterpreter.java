package se.kth.iv1351.view;

import java.util.Scanner;

import se.kth.iv1351.controller.CourseDBController;

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
            switch (CommandType.fromString(cmdLine.getCommand())) {
                case HELP:
                    if (cmdLine.getArguments().size() != 0){
                        System.out.println("help command doesn't accept any arguments");
                        break;
                    }
                    for (CommandType command : CommandType.values()) {
                        if (command == CommandType.ILLEGAL_COMMAND) {
                            continue;
                        }
                        System.out.println(command.getCommand());
                    }
                    break;
                case QUIT:
                    stop();
                    break;
                
                default:
                    System.out.println("illegal command");
            }
        } catch (Exception e) {
            System.out.println("Operation failed");
            System.out.println(e.getMessage());
            e.printStackTrace();
        }
    }

    private String readNextLine() {
        System.out.print(PROMPT);
        return inputScanner.nextLine();
    }


}

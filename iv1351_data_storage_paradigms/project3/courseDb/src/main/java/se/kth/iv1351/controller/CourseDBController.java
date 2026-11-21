package se.kth.iv1351.controller;

import se.kth.iv1351.config.Config;
import se.kth.iv1351.integration.DatabaseConnection;
import se.kth.iv1351.integration.DatabaseConnectionException;

public class CourseDBController {
    private DatabaseConnection dbConnection;

    public CourseDBController(){
        try{
            dbConnection = new DatabaseConnection(Config.USERNAME, Config.PASSWORD);
        }
        catch (DatabaseConnectionException exception){
            throw new RuntimeException(exception);
        }
    }
}

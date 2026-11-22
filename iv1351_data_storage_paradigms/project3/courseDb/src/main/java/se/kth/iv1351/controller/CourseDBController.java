package se.kth.iv1351.controller;

import java.sql.SQLException;

import se.kth.iv1351.config.Config;
import se.kth.iv1351.integration.CourseDBException;
import se.kth.iv1351.integration.CourseInstanceDAO;
import se.kth.iv1351.integration.DatabaseConnection;
import se.kth.iv1351.integration.DatabaseConnectionException;

public class CourseDBController {
    private DatabaseConnection dbConnection;
    private CourseInstanceDAO courseInstanceDAO;

    public CourseDBController(){
        try{
            dbConnection = new DatabaseConnection(Config.USERNAME, Config.PASSWORD);
            courseInstanceDAO = new CourseInstanceDAO(dbConnection);
        }
        catch (DatabaseConnectionException | SQLException exception){
            throw new RuntimeException(exception);
        }
    }

    public void test(){
        try {
            int hours = courseInstanceDAO.findPlannedHoursByCourseInstance("2026-50000011");
            System.out.println(hours);
        } catch (CourseDBException e) {
            e.printStackTrace();
        }
    }
}

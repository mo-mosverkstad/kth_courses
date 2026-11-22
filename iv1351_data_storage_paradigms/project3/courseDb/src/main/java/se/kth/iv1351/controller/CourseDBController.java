package se.kth.iv1351.controller;

import java.math.BigDecimal;

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
            dbConnection = new DatabaseConnection(Config.DATABASE_NAME, Config.USERNAME,
                                                  Config.PASSWORD);
            courseInstanceDAO = new CourseInstanceDAO(dbConnection);
        }
        catch (DatabaseConnectionException | CourseDBException exception){
            throw new RuntimeException(exception);
        }
    }

    public void test(){
        try {
            BigDecimal hours = courseInstanceDAO.findPlannedHoursByCourseInstance("2026-50000011");
            dbConnection.commit();
            System.out.println(hours);
        } catch (CourseDBException | DatabaseConnectionException exception) {
            rollback();
            exception.printStackTrace();
        }
    }

    private void rollback(){
        try{
            dbConnection.rollback();
        }
        catch (DatabaseConnectionException exception){
            exception.printStackTrace();
        }
    }
}

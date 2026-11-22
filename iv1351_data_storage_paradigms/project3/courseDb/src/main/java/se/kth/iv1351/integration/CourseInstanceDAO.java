package se.kth.iv1351.integration;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

public class CourseInstanceDAO {
    private DatabaseConnection databaseConnection;
    private PreparedStatement plannedHoursByInstanceStmt;
    public CourseInstanceDAO(DatabaseConnection databaseConnection) throws SQLException{
        this.databaseConnection = databaseConnection;
        prepareStatements();
    }

    public int findPlannedHoursByCourseInstance(String courseInstanceId) throws CourseDBException {
        String failureMsg = "Could not search for specific course instance";
        ResultSet result = null;
        try{
            plannedHoursByInstanceStmt.setString(1, courseInstanceId);
            result = plannedHoursByInstanceStmt.executeQuery();
            if (result.next()){
                return result.getInt("total_planned_hours");
            }
        }
        catch (SQLException sqlException){
            handleException(failureMsg, sqlException);
        }
        finally{
            closeResultSet(failureMsg, result);
        }
        return 0;
    }

    private void prepareStatements() throws SQLException {
        Connection connection = databaseConnection.getConnection();
        plannedHoursByInstanceStmt = connection.prepareStatement("SELECT\r\n" + //
                        "    COALESCE(\r\n" + //
                        "        SUM(\r\n" + //
                        "            planned_activity.planned_hours * teaching_activity.multiplication_factor\r\n" + //
                        "        ),\r\n" + //
                        "        0\r\n" + //
                        "    ) AS total_planned_hours\r\n" + //
                        "FROM course_instance\r\n" + //
                        "INNER JOIN planned_activity\r\n" + //
                        "ON course_instance.id = planned_activity.course_instance_id\r\n" + //
                        "INNER JOIN teaching_activity\r\n" + //
                        "ON teaching_activity.id = planned_activity.teaching_activity_id\r\n" + //
                        "WHERE course_instance.instance_id = ?");
    }

    private void handleException(String failureMsg, Exception cause) throws CourseDBException {
        String completeFailureMsg = failureMsg;
        try {
            databaseConnection.getConnection().rollback();
        } catch (SQLException rollbackExc) {
            completeFailureMsg = completeFailureMsg +
                    ". Also failed to rollback transaction because of: " + rollbackExc.getMessage();
        }

        if (cause != null) {
            throw new CourseDBException(completeFailureMsg, cause);
        } else {
            throw new CourseDBException(completeFailureMsg);
        }
    }

    private void closeResultSet(String failureMsg, ResultSet result) throws CourseDBException {
        if (result == null) {
            return;
        }
        try {
            result.close();
        } catch (Exception e) {
            throw new CourseDBException(failureMsg + " Could not close result set.", e);
        }
    }
}

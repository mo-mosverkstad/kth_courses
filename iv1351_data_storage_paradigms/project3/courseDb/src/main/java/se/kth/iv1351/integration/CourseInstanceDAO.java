package se.kth.iv1351.integration;

import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

public class CourseInstanceDAO {
    private final DatabaseConnection databaseConnection;
    private PreparedStatement plannedHoursByInstanceStmt;

    public CourseInstanceDAO(DatabaseConnection databaseConnection) throws CourseDBException{
        this.databaseConnection = databaseConnection;
        try{
            prepareStatements();
        }
        catch (SQLException sqlException){
            throw new CourseDBException("Could not prepare the statements of "
                                        + getClass().getSimpleName(), sqlException);
        }
    }

    public BigDecimal findPlannedHoursByCourseInstance(String courseInstanceId)
            throws CourseDBException {
        String failureMsg = "Could not search for specific course instance";
        ResultSet result = null;
        try{
            plannedHoursByInstanceStmt.setString(1, courseInstanceId);
            result = plannedHoursByInstanceStmt.executeQuery();
            if (result.next()){
                return result.getBigDecimal("total_planned_hours");
            }
        }
        catch (SQLException sqlException){
            throw new CourseDBException(failureMsg, sqlException);
        }
        finally{
            closeResultSet(failureMsg, result);
        }
        return BigDecimal.ZERO;
    }

    private void prepareStatements() throws SQLException {
        Connection connection = databaseConnection.getConnection();
        plannedHoursByInstanceStmt = connection.prepareStatement("""
            SELECT
                COALESCE(
                    SUM(
                        planned_activity.planned_hours * teaching_activity.multiplication_factor
                    ),
                    0
                ) AS total_planned_hours
            FROM course_instance
            INNER JOIN planned_activity
            ON course_instance.id = planned_activity.course_instance_id
            INNER JOIN teaching_activity
            ON teaching_activity.id = planned_activity.teaching_activity_id
            WHERE course_instance.instance_id = ?""");
    }

    private void closeResultSet(String failureMsg, ResultSet result) throws CourseDBException {
        if (result == null) {
            return;
        }
        try {
            result.close();
        } catch (Exception exception) {
            throw new CourseDBException(failureMsg + " Could not close result set.", exception);
        }
    }
}

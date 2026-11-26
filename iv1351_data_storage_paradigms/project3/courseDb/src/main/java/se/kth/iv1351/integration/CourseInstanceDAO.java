package se.kth.iv1351.integration;

import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

import se.kth.iv1351.dto.CourseInstanceDTO;

/** Reads course-instance information and teaching-hour totals. */
public class CourseInstanceDAO extends AbstractDAO {
    private PreparedStatement courseInstanceByIdStmt;
    private PreparedStatement plannedHoursByInstanceStmt;
    private PreparedStatement allocatedHoursByInstanceStmt;

    public CourseInstanceDAO(DatabaseConnection databaseConnection) throws CourseDBException {
        super(databaseConnection);
    }

    /** Returns this year's course instance, or {@code null} if it does not exist. */
    public CourseInstanceDTO findCurrentYearCourseInstance(String instanceId)
            throws CourseDBException {
        String failureMsg = "Could not read course instance: " + instanceId;
        ResultSet result = null;
        try {
            courseInstanceByIdStmt.setString(1, instanceId);
            result = courseInstanceByIdStmt.executeQuery();
            if (result.next()) {
                return new CourseInstanceDTO(
                    result.getString("instance_id"),
                    result.getString("course_code"),
                    result.getString("course_name"),
                    result.getString("period_name"),
                    result.getInt("academic_year"),
                    result.getBigDecimal("hp"),
                    result.getInt("num_students")
                );
            }
            return null;
        } catch (SQLException exception) {
            throw new CourseDBException(failureMsg, exception);
        } finally {
            closeResultSet(failureMsg, result);
        }
    }

    public BigDecimal findPlannedHoursByCourseInstance(String instanceId) throws CourseDBException {
        return findHours(instanceId, plannedHoursByInstanceStmt, "total_planned_hours");
    }

    public BigDecimal findAllocatedHoursByCourseInstance(String instanceId) throws CourseDBException {
        return findHours(instanceId, allocatedHoursByInstanceStmt, "total_allocation_hours");
    }

    @Override
    protected void prepareStatements() throws SQLException {
        Connection connection = databaseConnection.getConnection();
        courseInstanceByIdStmt = connection.prepareStatement("""
            SELECT course_instance.instance_id,
                   course.course_code,
                   course.course_name,
                   period.period_name,
                   academic_period.academic_year,
                   course_layout.hp,
                   course_instance.num_students
            FROM course_instance
            INNER JOIN course_layout ON course_layout.id = course_instance.course_layout_id
            INNER JOIN course ON course.id = course_layout.course_id
            INNER JOIN academic_period ON academic_period.id = course_instance.academic_period_id
            INNER JOIN period ON period.id = academic_period.period_id
            WHERE course_instance.instance_id = ?
              AND academic_period.academic_year = EXTRACT(YEAR FROM CURRENT_DATE)
            """);

        plannedHoursByInstanceStmt = connection.prepareStatement("""
            SELECT COALESCE(ROUND(SUM(planned_activity.planned_hours
                                      * teaching_activity.multiplication_factor)), 0)
                   AS total_planned_hours
            FROM course_instance
            INNER JOIN planned_activity
                ON planned_activity.course_instance_id = course_instance.id
            INNER JOIN teaching_activity
                ON teaching_activity.id = planned_activity.teaching_activity_id
            WHERE course_instance.instance_id = ?
            """);

        allocatedHoursByInstanceStmt = connection.prepareStatement("""
            SELECT COALESCE(ROUND(SUM(teaching_allocation.allocation_hours
                                      * teaching_activity.multiplication_factor)), 0)
                   AS total_allocation_hours
            FROM course_instance
            INNER JOIN planned_activity
                ON planned_activity.course_instance_id = course_instance.id
            INNER JOIN teaching_activity
                ON teaching_activity.id = planned_activity.teaching_activity_id
            INNER JOIN teaching_allocation
                ON teaching_allocation.planned_activity_id = planned_activity.id
            WHERE course_instance.instance_id = ?
            """);
    }

    private BigDecimal findHours(String instanceId, PreparedStatement statement, String column) throws CourseDBException {
        String failureMsg = "Could not read " + column + " for course instance: " + instanceId;
        ResultSet result = null;
        try {
            statement.setString(1, instanceId);
            result = statement.executeQuery();
            return result.next() ? result.getBigDecimal(column) : BigDecimal.ZERO;
        } catch (SQLException exception) {
            throw new CourseDBException(failureMsg, exception);
        } finally {
            closeResultSet(failureMsg, result);
        }
    }
}

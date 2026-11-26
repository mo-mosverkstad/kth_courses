package se.kth.iv1351.integration;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

import se.kth.iv1351.dto.AllocationDTO;
import se.kth.iv1351.dto.PlannedActivityDTO;

public final class TeachingActivityDAO extends AbstractDAO {
    private PreparedStatement findAllocationsByTeacherAndPeriodStmt;
    private PreparedStatement findAllocationsByCourseInstanceStmt;
    private PreparedStatement findPlannedActivityStmt;
    private PreparedStatement createAllocationStmt;
    private PreparedStatement deleteAllocationStmt;

    private final String ALLOCATION_QUERY = """
        SELECT employee.employment_id,
                person.first_name || ' ' || person.last_name AS teacher_name,
                course_instance.instance_id,
                course.course_code,
                teaching_activity.activity_name,
                teaching_allocation.allocation_hours
        FROM teaching_allocation
        INNER JOIN employee ON employee.id = teaching_allocation.employee_id
        INNER JOIN person ON person.id = employee.person_id
        INNER JOIN planned_activity ON planned_activity.id = teaching_allocation.planned_activity_id
        INNER JOIN teaching_activity ON teaching_activity.id = planned_activity.teaching_activity_id
        INNER JOIN course_instance ON course_instance.id = planned_activity.course_instance_id
        INNER JOIN course_layout ON course_layout.id = course_instance.course_layout_id
        INNER JOIN course ON course.id = course_layout.course_id
        INNER JOIN academic_period ON academic_period.id = course_instance.academic_period_id
        INNER JOIN period ON period.id = academic_period.period_id
    """;
    

    public TeachingActivityDAO(DatabaseConnection databaseConnection) throws CourseDBException {
        super(databaseConnection);
    }

    /**
     * Reads all allocations of the specified teacher in the specified academic period.
     *
     * @param employmentId The business id of the employment.
     * @param academicYear The academic year.
     * @param periodName   The name of the period.
     * @return A list with all matching allocations, which is empty if there are none.
     * @throws CourseDBException If unable to read the allocations.
     */
    public List<AllocationDTO> findAllocationsByTeacherAndPeriod(int employmentId, int academicYear, String periodName) throws CourseDBException {
        String failureMsg = "Could not read the allocations of the employee: " + employmentId;
        ResultSet result = null;
        try {
            findAllocationsByTeacherAndPeriodStmt.setInt(1, employmentId);
            findAllocationsByTeacherAndPeriodStmt.setInt(2, academicYear);
            findAllocationsByTeacherAndPeriodStmt.setString(3, periodName);
            result = findAllocationsByTeacherAndPeriodStmt.executeQuery();
            return readAllocation(result);
        }
        catch (SQLException sqlException){
            throw new CourseDBException(failureMsg, sqlException);
        }
        finally{
            closeResultSet(failureMsg, result);
        }
    }

    /**
     * Reads all allocations of the specified course instance.
     *
     * @param instanceId The business id of the course instance.
     * @return A list with all matching allocations, which is empty if there are none.
     * @throws CourseDBException If unable to read the allocations.
     */
    public List<AllocationDTO> findAllocationsByCourseInstance(String instanceId)
            throws CourseDBException {
        String failureMsg = "Could not read the allocations of: " + instanceId;
        ResultSet result = null;
        try {
            findAllocationsByCourseInstanceStmt.setString(1, instanceId);
            result = findAllocationsByCourseInstanceStmt.executeQuery();
            return readAllocation(result);
        } catch (SQLException sqlException) {
            throw new CourseDBException(failureMsg, sqlException);
        } finally {
            closeResultSet(failureMsg, result);
        }
    }

    private List<AllocationDTO> readAllocation(ResultSet result) throws SQLException{
        List<AllocationDTO> allocations = new ArrayList<>();
        while (result.next()) {
            allocations.add(new AllocationDTO(
                result.getInt("employment_id"),
                result.getString("teacher_name"),
                result.getString("instance_id"),
                result.getString("course_code"),
                result.getString("activity_name"),
                result.getInt("allocation_hours")
            ));
        }
        return allocations;
    }

    /**
     * Reads the planned activity of the specified teaching activity in the specified
     * course instance.
     *
     * @param instanceId   The business id of the course instance.
     * @param activityName The name of the teaching activity.
     * @return The planned activity, or <code>null</code> if there is no such planned
     *         activity.
     * @throws CourseDBException If unable to read the planned activity.
     */
    public PlannedActivityDTO findPlannedActivity(String instanceId, String activityName) throws CourseDBException {
        String failureMsg = "Could not read the planned activity " + activityName + " of: " + instanceId;
        ResultSet result = null;
        try {
            findPlannedActivityStmt.setString(1, instanceId);
            findPlannedActivityStmt.setString(2, activityName);
            result = findPlannedActivityStmt.executeQuery();
            if (result.next()) {
                return new PlannedActivityDTO(
                    result.getInt("id"),
                    result.getString("instance_id"),
                    result.getString("activity_name"),
                    result.getInt("planned_hours")
                );
            }
        } 
        catch (SQLException sqlException) {
            throw new CourseDBException(failureMsg, sqlException);
        }
        finally {
            closeResultSet(failureMsg, result);
        }
        return null;
    }

    /**
     * Creates an allocation of the specified teacher to the specified planned activity.
     *
     * @param plannedActivityId The database id of the planned activity.
     * @param employmentId      The business id of the employment of the teacher.
     * @param allocationHours   The allocated raw hours.
     * @throws CourseDBException If unable to create the allocation.
     */
    public void createAllocation(int plannedActivityId, int employmentId, int allocationHours) throws CourseDBException {
        String failureMsg = "Could not create an allocation of the employee " + employmentId
                            + " to the planned activity " + plannedActivityId;
        try {
            createAllocationStmt.setInt(1, plannedActivityId);
            createAllocationStmt.setInt(2, employmentId);
            createAllocationStmt.setInt(3, allocationHours);
            int updatedRows = createAllocationStmt.executeUpdate();
            if (updatedRows != 1) {
                throw new CourseDBException(failureMsg, null);
            }
        }
        catch (SQLException sqlException) {
            throw new CourseDBException(failureMsg, sqlException);
        }
    }

    /**
     * Deletes the allocation of the specified teacher to the specified planned activity.
     *
     * @param plannedActivityId The database id of the planned activity.
     * @param employmentId      The business id of the employment of the teacher.
     * @throws CourseDBException If unable to delete the allocation, or if there is no such
     *                           allocation.
     */
    public void deleteAllocation(int plannedActivityId, int employmentId) throws CourseDBException {
        String failureMsg = "Could not delete the allocation of the employee " + employmentId
                            + " to the planned activity " + plannedActivityId;
        try {
            deleteAllocationStmt.setInt(1, plannedActivityId);
            deleteAllocationStmt.setInt(2, employmentId);
            int updatedRows = deleteAllocationStmt.executeUpdate();
            if (updatedRows != 1) {
                throw new CourseDBException(failureMsg, null);
            }
        }
        catch (SQLException sqlException) {
            throw new CourseDBException(failureMsg, sqlException);
        }
    }

    protected void prepareStatements() throws SQLException{
        Connection connection = databaseConnection.getConnection();
        findAllocationsByTeacherAndPeriodStmt = connection.prepareStatement(ALLOCATION_QUERY + """
            WHERE employee.employment_id = ?
            AND academic_period.academic_year = ?
            AND period.period_name = ?
            ORDER BY course_instance.instance_id, teaching_activity.activity_name;
        """);
        findAllocationsByCourseInstanceStmt = connection.prepareStatement(ALLOCATION_QUERY + """
            WHERE course_instance.instance_id = ?
            ORDER BY teacher_name, teaching_activity.activity_name;
        """);
        findPlannedActivityStmt = connection.prepareStatement("""
            SELECT planned_activity.id,
                    course_instance.instance_id,
                    teaching_activity.activity_name,
                    planned_activity.planned_hours
            FROM planned_activity
            INNER JOIN course_instance ON course_instance.id = planned_activity.course_instance_id
            INNER JOIN teaching_activity ON teaching_activity.id = planned_activity.teaching_activity_id
            WHERE course_instance.instance_id = ? AND teaching_activity.activity_name = ?;
        """);
        createAllocationStmt = connection.prepareStatement("""
            INSERT INTO teaching_allocation (planned_activity_id, employee_id, allocation_hours)
            VALUES (?, (SELECT employee.id FROM employee WHERE employee.employment_id = ?), ?);
        """);
        deleteAllocationStmt = connection.prepareStatement("""
            DELETE FROM teaching_allocation
            WHERE teaching_allocation.planned_activity_id = ?
                AND teaching_allocation.employee_id =
                    (SELECT employee.id FROM employee WHERE employee.employment_id = ?)
        """);
    }
}

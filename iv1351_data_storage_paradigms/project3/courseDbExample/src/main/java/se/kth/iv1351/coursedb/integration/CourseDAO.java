package se.kth.iv1351.coursedb.integration;

import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.List;

import se.kth.iv1351.coursedb.dto.AllocationDTO;
import se.kth.iv1351.coursedb.dto.CourseInstanceDTO;
import se.kth.iv1351.coursedb.dto.EmployeeDTO;
import se.kth.iv1351.coursedb.dto.PlannedActivityDTO;
import se.kth.iv1351.coursedb.dto.TeachingActivityDTO;

/**
 * Handles all database access of the course database. All methods either create, read,
 * update or delete rows, no method contains any business rule. Transactions are not
 * committed here, except that a failed operation is rolled back. It is the caller that
 * decides when a transaction is finished, by calling {@link #commit()}.
 */
public class CourseDAO {
    private static final String COURSE_INSTANCE_QUERY = """
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
            WHERE course_instance.instance_id = ?""";

    private static final String ALLOCATION_QUERY = """
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
            INNER JOIN period ON period.id = academic_period.period_id""";

    private Connection connection;
    private PreparedStatement findCourseInstanceStmt;
    private PreparedStatement findCourseInstanceLockingForUpdateStmt;
    private PreparedStatement findPlannedHoursStmt;
    private PreparedStatement findAllocatedHoursStmt;
    private PreparedStatement findAverageSalaryStmt;
    private PreparedStatement updateNumStudentsStmt;
    private PreparedStatement findPolicyStmt;
    private PreparedStatement findEmployeeLockingForUpdateStmt;
    private PreparedStatement findAllocationsByTeacherAndPeriodStmt;
    private PreparedStatement findAllocationsByCourseInstanceStmt;
    private PreparedStatement findPlannedActivityStmt;
    private PreparedStatement createAllocationStmt;
    private PreparedStatement deleteAllocationStmt;
    private PreparedStatement createTeachingActivityStmt;
    private PreparedStatement createPlannedActivityStmt;

    /**
     * Connects to the course database and prepares all statements.
     *
     * @throws CourseDBException If unable to connect to the database.
     */
    public CourseDAO() throws CourseDBException {
        try {
            connectToCourseDB();
            prepareStatements();
        } catch (ClassNotFoundException | SQLException exception) {
            throw new CourseDBException("Could not connect to the course database.", exception);
        }
    }

    /**
     * Reads the course instance with the specified business id.
     *
     * @param instanceId The business id of the course instance.
     * @return The course instance, or <code>null</code> if there is no such course instance.
     * @throws CourseDBException If unable to read the course instance.
     */
    public CourseInstanceDTO findCourseInstance(String instanceId) throws CourseDBException {
        return findCourseInstance(instanceId, findCourseInstanceStmt);
    }

    /**
     * Reads the course instance with the specified business id, and locks the row until
     * the transaction is finished. Must be used when the course instance is read in order
     * to be updated, otherwise the lost update anomaly may occur.
     *
     * @param instanceId The business id of the course instance.
     * @return The course instance, or <code>null</code> if there is no such course instance.
     * @throws CourseDBException If unable to read the course instance.
     */
    public CourseInstanceDTO findCourseInstanceForUpdate(String instanceId)
            throws CourseDBException {
        return findCourseInstance(instanceId, findCourseInstanceLockingForUpdateStmt);
    }

    /**
     * Reads the planned hours of the specified course instance, with the multiplication
     * factor of each teaching activity applied.
     *
     * @param instanceId The business id of the course instance.
     * @return The planned hours, or zero if there are no planned activities.
     * @throws CourseDBException If unable to read the planned hours.
     */
    public int findPlannedHoursByCourseInstance(String instanceId) throws CourseDBException {
        return findHours(instanceId, findPlannedHoursStmt,
                         "Could not read the planned hours of: " + instanceId);
    }

    /**
     * Reads the hours that are allocated to teachers in the specified course instance,
     * with the multiplication factor of each teaching activity applied.
     *
     * @param instanceId The business id of the course instance.
     * @return The allocated hours, or zero if there are no allocations.
     * @throws CourseDBException If unable to read the allocated hours.
     */
    public int findAllocatedHoursByCourseInstance(String instanceId) throws CourseDBException {
        return findHours(instanceId, findAllocatedHoursStmt,
                         "Could not read the allocated hours of: " + instanceId);
    }

    /**
     * Reads the average of the current monthly salary of all employees. Since the table
     * <code>employee_salary</code> contains one row per salary change, only the latest
     * salary of each employee is included.
     *
     * @return The average monthly salary, or zero if there are no salaries.
     * @throws CourseDBException If unable to read the salaries.
     */
    public BigDecimal findAverageTeacherSalary() throws CourseDBException {
        String failureMsg = "Could not read the average salary.";
        ResultSet result = null;
        try {
            result = findAverageSalaryStmt.executeQuery();
            if (result.next() && result.getBigDecimal("average_salary") != null) {
                return result.getBigDecimal("average_salary");
            }
            return BigDecimal.ZERO;
        } catch (SQLException exception) {
            handleException(failureMsg, exception);
        } finally {
            closeResultSet(failureMsg, result);
        }
        return BigDecimal.ZERO;
    }

    /**
     * Updates the number of registered students of the specified course instance.
     *
     * @param courseInstance The course instance to update.
     * @throws CourseDBException If unable to update the course instance.
     */
    public void updateCourseInstance(CourseInstanceDTO courseInstance) throws CourseDBException {
        String failureMsg = "Could not update the course instance: " + courseInstance;
        try {
            updateNumStudentsStmt.setInt(1, courseInstance.numStudents());
            updateNumStudentsStmt.setString(2, courseInstance.instanceId());
            int updatedRows = updateNumStudentsStmt.executeUpdate();
            if (updatedRows != 1) {
                handleException(failureMsg, null);
            }
        } catch (SQLException exception) {
            handleException(failureMsg, exception);
        }
    }

    /**
     * Reads the value of the policy with the specified name.
     *
     * @param policyName The name of the policy.
     * @return The value of the policy.
     * @throws CourseDBException If unable to read the policy, or if there is no policy
     *                           with the specified name.
     */
    public int findPolicyByName(String policyName) throws CourseDBException {
        String failureMsg = "Could not read the policy: " + policyName;
        ResultSet result = null;
        try {
            findPolicyStmt.setString(1, policyName);
            result = findPolicyStmt.executeQuery();
            if (result.next()) {
                return result.getInt("policy_value");
            }
            handleException(failureMsg, null);
        } catch (SQLException exception) {
            handleException(failureMsg, exception);
        } finally {
            closeResultSet(failureMsg, result);
        }
        return 0;
    }

    /**
     * Reads the employee with the specified employment id, and locks the row until the
     * transaction is finished. Must be used when the allocations of a teacher are read in
     * order to decide whether a new allocation is allowed, since the allocation rows that
     * the decision is based on may not exist yet and can therefore not be locked.
     *
     * @param employmentId The business id of the employment.
     * @return The employee, or <code>null</code> if there is no such employee.
     * @throws CourseDBException If unable to read the employee.
     */
    public EmployeeDTO findEmployeeForUpdate(int employmentId) throws CourseDBException {
        String failureMsg = "Could not read the employee: " + employmentId;
        ResultSet result = null;
        try {
            findEmployeeLockingForUpdateStmt.setInt(1, employmentId);
            result = findEmployeeLockingForUpdateStmt.executeQuery();
            if (result.next()) {
                return new EmployeeDTO(result.getInt("employment_id"),
                                       result.getString("first_name"),
                                       result.getString("last_name"),
                                       result.getString("job_title_name"));
            }
        } catch (SQLException exception) {
            handleException(failureMsg, exception);
        } finally {
            closeResultSet(failureMsg, result);
        }
        return null;
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
    public List<AllocationDTO> findAllocationsByTeacherAndPeriod(int employmentId,
                                                                 int academicYear,
                                                                 String periodName)
            throws CourseDBException {
        String failureMsg = "Could not read the allocations of the employee: " + employmentId;
        ResultSet result = null;
        try {
            findAllocationsByTeacherAndPeriodStmt.setInt(1, employmentId);
            findAllocationsByTeacherAndPeriodStmt.setInt(2, academicYear);
            findAllocationsByTeacherAndPeriodStmt.setString(3, periodName);
            result = findAllocationsByTeacherAndPeriodStmt.executeQuery();
            return readAllocations(result);
        } catch (SQLException exception) {
            handleException(failureMsg, exception);
        } finally {
            closeResultSet(failureMsg, result);
        }
        return new ArrayList<>();
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
            return readAllocations(result);
        } catch (SQLException exception) {
            handleException(failureMsg, exception);
        } finally {
            closeResultSet(failureMsg, result);
        }
        return new ArrayList<>();
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
    public PlannedActivityDTO findPlannedActivity(String instanceId, String activityName)
            throws CourseDBException {
        String failureMsg = "Could not read the planned activity " + activityName + " of: "
                            + instanceId;
        ResultSet result = null;
        try {
            findPlannedActivityStmt.setString(1, instanceId);
            findPlannedActivityStmt.setString(2, activityName);
            result = findPlannedActivityStmt.executeQuery();
            if (result.next()) {
                return new PlannedActivityDTO(result.getInt("id"),
                                              result.getString("instance_id"),
                                              result.getString("activity_name"),
                                              result.getInt("planned_hours"));
            }
        } catch (SQLException exception) {
            handleException(failureMsg, exception);
        } finally {
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
    public void createAllocation(int plannedActivityId, int employmentId, int allocationHours)
            throws CourseDBException {
        String failureMsg = "Could not create an allocation of the employee " + employmentId
                            + " to the planned activity " + plannedActivityId;
        try {
            createAllocationStmt.setInt(1, plannedActivityId);
            createAllocationStmt.setInt(2, employmentId);
            createAllocationStmt.setInt(3, allocationHours);
            int updatedRows = createAllocationStmt.executeUpdate();
            if (updatedRows != 1) {
                handleException(failureMsg, null);
            }
        } catch (SQLException exception) {
            handleException(failureMsg, exception);
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
    public void deleteAllocation(int plannedActivityId, int employmentId)
            throws CourseDBException {
        String failureMsg = "Could not delete the allocation of the employee " + employmentId
                            + " to the planned activity " + plannedActivityId;
        try {
            deleteAllocationStmt.setInt(1, plannedActivityId);
            deleteAllocationStmt.setInt(2, employmentId);
            int updatedRows = deleteAllocationStmt.executeUpdate();
            if (updatedRows != 1) {
                handleException(failureMsg, null);
            }
        } catch (SQLException exception) {
            handleException(failureMsg, exception);
        }
    }

    /**
     * Creates the specified teaching activity.
     *
     * @param teachingActivity The teaching activity to create.
     * @throws CourseDBException If unable to create the teaching activity.
     */
    public void createTeachingActivity(TeachingActivityDTO teachingActivity)
            throws CourseDBException {
        String failureMsg = "Could not create the teaching activity: " + teachingActivity;
        try {
            createTeachingActivityStmt.setString(1, teachingActivity.activityName());
            createTeachingActivityStmt.setBigDecimal(2, teachingActivity.multiplicationFactor());
            int updatedRows = createTeachingActivityStmt.executeUpdate();
            if (updatedRows != 1) {
                handleException(failureMsg, null);
            }
        } catch (SQLException exception) {
            handleException(failureMsg, exception);
        }
    }

    /**
     * Creates a planned activity of the specified teaching activity in the specified
     * course instance.
     *
     * @param instanceId   The business id of the course instance.
     * @param activityName The name of the teaching activity.
     * @param plannedHours The planned raw hours.
     * @throws CourseDBException If unable to create the planned activity.
     */
    public void createPlannedActivity(String instanceId, String activityName, int plannedHours)
            throws CourseDBException {
        String failureMsg = "Could not create the planned activity " + activityName + " of: "
                            + instanceId;
        try {
            createPlannedActivityStmt.setInt(1, plannedHours);
            createPlannedActivityStmt.setString(2, activityName);
            createPlannedActivityStmt.setString(3, instanceId);
            int updatedRows = createPlannedActivityStmt.executeUpdate();
            if (updatedRows != 1) {
                handleException(failureMsg, null);
            }
        } catch (SQLException exception) {
            handleException(failureMsg, exception);
        }
    }

    /**
     * Commits the current transaction.
     *
     * @throws CourseDBException If unable to commit the current transaction.
     */
    public void commit() throws CourseDBException {
        try {
            connection.commit();
        } catch (SQLException exception) {
            handleException("Failed to commit.", exception);
        }
    }

    /**
     * Rolls the current transaction back.
     *
     * @throws CourseDBException If unable to roll the current transaction back.
     */
    public void rollback() throws CourseDBException {
        try {
            connection.rollback();
        } catch (SQLException exception) {
            throw new CourseDBException("Failed to roll back.", exception);
        }
    }

    private CourseInstanceDTO findCourseInstance(String instanceId, PreparedStatement statement)
            throws CourseDBException {
        String failureMsg = "Could not read the course instance: " + instanceId;
        ResultSet result = null;
        try {
            statement.setString(1, instanceId);
            result = statement.executeQuery();
            if (result.next()) {
                return new CourseInstanceDTO(result.getString("instance_id"),
                                             result.getString("course_code"),
                                             result.getString("course_name"),
                                             result.getString("period_name"),
                                             result.getInt("academic_year"),
                                             result.getBigDecimal("hp"),
                                             result.getInt("num_students"));
            }
        } catch (SQLException exception) {
            handleException(failureMsg, exception);
        } finally {
            closeResultSet(failureMsg, result);
        }
        return null;
    }

    private int findHours(String instanceId, PreparedStatement statement, String failureMsg)
            throws CourseDBException {
        ResultSet result = null;
        try {
            statement.setString(1, instanceId);
            result = statement.executeQuery();
            if (result.next()) {
                return result.getInt("hours");
            }
        } catch (SQLException exception) {
            handleException(failureMsg, exception);
        } finally {
            closeResultSet(failureMsg, result);
        }
        return 0;
    }

    private List<AllocationDTO> readAllocations(ResultSet result) throws SQLException {
        List<AllocationDTO> allocations = new ArrayList<>();
        while (result.next()) {
            allocations.add(new AllocationDTO(result.getInt("employment_id"),
                                              result.getString("teacher_name"),
                                              result.getString("instance_id"),
                                              result.getString("course_code"),
                                              result.getString("activity_name"),
                                              result.getInt("allocation_hours")));
        }
        return allocations;
    }

    private void connectToCourseDB() throws ClassNotFoundException, SQLException {
        connection = DriverManager.getConnection(
                "jdbc:postgresql://localhost:5432/course_database", "postgres", "postgres");
        connection.setAutoCommit(false);
    }

    private void prepareStatements() throws SQLException {
        findCourseInstanceStmt = connection.prepareStatement(COURSE_INSTANCE_QUERY);

        findCourseInstanceLockingForUpdateStmt = connection.prepareStatement(
                COURSE_INSTANCE_QUERY + " FOR NO KEY UPDATE OF course_instance");

        findPlannedHoursStmt = connection.prepareStatement("""
                SELECT COALESCE(ROUND(SUM(planned_activity.planned_hours
                                          * teaching_activity.multiplication_factor)), 0) AS hours
                FROM course_instance
                INNER JOIN planned_activity ON planned_activity.course_instance_id = course_instance.id
                INNER JOIN teaching_activity ON teaching_activity.id = planned_activity.teaching_activity_id
                WHERE course_instance.instance_id = ?""");

        findAllocatedHoursStmt = connection.prepareStatement("""
                SELECT COALESCE(ROUND(SUM(teaching_allocation.allocation_hours
                                          * teaching_activity.multiplication_factor)), 0) AS hours
                FROM course_instance
                INNER JOIN planned_activity ON planned_activity.course_instance_id = course_instance.id
                INNER JOIN teaching_activity ON teaching_activity.id = planned_activity.teaching_activity_id
                INNER JOIN teaching_allocation ON teaching_allocation.planned_activity_id = planned_activity.id
                WHERE course_instance.instance_id = ?""");

        findAverageSalaryStmt = connection.prepareStatement("""
                SELECT AVG(latest.salary) AS average_salary
                FROM (
                    SELECT DISTINCT ON (employee_salary.employee_id) employee_salary.salary
                    FROM employee_salary
                    ORDER BY employee_salary.employee_id, employee_salary.valid_from DESC
                ) AS latest""");

        updateNumStudentsStmt = connection.prepareStatement("""
                UPDATE course_instance
                SET num_students = ?
                WHERE instance_id = ?""");

        findPolicyStmt = connection.prepareStatement("""
                SELECT policy.policy_value
                FROM policy
                WHERE policy.policy_name = ?""");

        findEmployeeLockingForUpdateStmt = connection.prepareStatement("""
                SELECT employee.employment_id,
                       person.first_name,
                       person.last_name,
                       job_title.job_title_name
                FROM employee
                INNER JOIN person ON person.id = employee.person_id
                INNER JOIN job_title ON job_title.id = employee.job_title_id
                WHERE employee.employment_id = ?
                FOR NO KEY UPDATE OF employee""");

        findAllocationsByTeacherAndPeriodStmt = connection.prepareStatement(ALLOCATION_QUERY + """

                WHERE employee.employment_id = ?
                  AND academic_period.academic_year = ?
                  AND period.period_name = ?
                ORDER BY course_instance.instance_id, teaching_activity.activity_name""");

        findAllocationsByCourseInstanceStmt = connection.prepareStatement(ALLOCATION_QUERY + """

                WHERE course_instance.instance_id = ?
                ORDER BY teacher_name, teaching_activity.activity_name""");

        findPlannedActivityStmt = connection.prepareStatement("""
                SELECT planned_activity.id,
                       course_instance.instance_id,
                       teaching_activity.activity_name,
                       planned_activity.planned_hours
                FROM planned_activity
                INNER JOIN course_instance ON course_instance.id = planned_activity.course_instance_id
                INNER JOIN teaching_activity ON teaching_activity.id = planned_activity.teaching_activity_id
                WHERE course_instance.instance_id = ?
                  AND teaching_activity.activity_name = ?""");

        createAllocationStmt = connection.prepareStatement("""
                INSERT INTO teaching_allocation (planned_activity_id, employee_id, allocation_hours)
                VALUES (?,
                        (SELECT employee.id FROM employee WHERE employee.employment_id = ?),
                        ?)""");

        deleteAllocationStmt = connection.prepareStatement("""
                DELETE FROM teaching_allocation
                WHERE teaching_allocation.planned_activity_id = ?
                  AND teaching_allocation.employee_id =
                      (SELECT employee.id FROM employee WHERE employee.employment_id = ?)""");

        createTeachingActivityStmt = connection.prepareStatement("""
                INSERT INTO teaching_activity (activity_name, multiplication_factor)
                VALUES (?, ?)""");

        createPlannedActivityStmt = connection.prepareStatement("""
                INSERT INTO planned_activity (planned_hours, teaching_activity_id, course_instance_id)
                VALUES (?,
                        (SELECT teaching_activity.id FROM teaching_activity
                         WHERE teaching_activity.activity_name = ?),
                        (SELECT course_instance.id FROM course_instance
                         WHERE course_instance.instance_id = ?))""");
    }

    private void handleException(String failureMsg, Exception cause) throws CourseDBException {
        String completeFailureMsg = failureMsg;
        try {
            connection.rollback();
        } catch (SQLException rollbackException) {
            completeFailureMsg = completeFailureMsg
                                 + " Also failed to roll back the transaction because of: "
                                 + rollbackException.getMessage();
        }

        if (cause != null) {
            throw new CourseDBException(completeFailureMsg, cause);
        }
        throw new CourseDBException(completeFailureMsg);
    }

    private void closeResultSet(String failureMsg, ResultSet result) throws CourseDBException {
        if (result == null) {
            return;
        }
        try {
            result.close();
        } catch (Exception exception) {
            throw new CourseDBException(failureMsg + " Could not close the result set.",
                                        exception);
        }
    }
}

package se.kth.iv1351.controller;

import java.math.BigDecimal;
import java.util.List;

import se.kth.iv1351.config.Config;
import se.kth.iv1351.dto.AllocationDTO;
import se.kth.iv1351.dto.CourseInstanceDTO;
import se.kth.iv1351.dto.EmployeeDTO;
import se.kth.iv1351.dto.PlannedActivityDTO;
import se.kth.iv1351.dto.TeachingActivityDTO;
import se.kth.iv1351.dto.TeachingCostDTO;
import se.kth.iv1351.integration.CourseDBException;
import se.kth.iv1351.integration.CourseInstanceDAO;
import se.kth.iv1351.integration.DatabaseConnection;
import se.kth.iv1351.integration.DatabaseConnectionException;
import se.kth.iv1351.integration.EmployeeDAO;
import se.kth.iv1351.integration.PolicyDAO;
import se.kth.iv1351.integration.TeachingActivityDAO;
import se.kth.iv1351.model.Amount;
import se.kth.iv1351.model.CourseException;
import se.kth.iv1351.model.CourseInstance;
import se.kth.iv1351.model.RejectedException;
import se.kth.iv1351.model.TeacherLoad;
import se.kth.iv1351.model.TeachingCost;

/** Coordinates the teaching-cost use case and owns its transaction boundary. */
public class CourseDBController {
    private static final String ALLOCATION_POLICY = "allocation_rule";

    private final DatabaseConnection dbConnection;
    private final CourseInstanceDAO courseInstanceDAO;
    private final EmployeeDAO employeeDAO;
    private final TeachingActivityDAO teachingActivityDAO;
    private final PolicyDAO policyDAO;

    public CourseDBController() {
        try {
            dbConnection = new DatabaseConnection(Config.DATABASE_NAME, Config.USERNAME, Config.PASSWORD);
            courseInstanceDAO = new CourseInstanceDAO(dbConnection);
            employeeDAO = new EmployeeDAO(dbConnection);
            teachingActivityDAO = new TeachingActivityDAO(dbConnection);
            policyDAO = new PolicyDAO(dbConnection);
        } catch (DatabaseConnectionException | CourseDBException exception) {
            throw new IllegalStateException("Could not initialize the course database", exception);
        }
    }

    /**
     * Calculates the planned and allocated cost for a course instance in the current year.
     * All reads use one transaction so they observe one consistent database snapshot.
     */
    public TeachingCostDTO calculateTeachingCost(String instanceId) throws CourseException {
        try {
            CourseInstanceDTO courseInstance = courseInstanceDAO.findCurrentYearCourseInstance(instanceId);
            if (courseInstance == null) {
                throw new CourseException("No course instance for the current year: " + instanceId);
            }

            BigDecimal plannedHours = courseInstanceDAO.findPlannedHoursByCourseInstance(instanceId);
            BigDecimal allocatedHours = courseInstanceDAO.findAllocatedHoursByCourseInstance(instanceId);
            Amount averageTeacherSalary = new Amount(employeeDAO.findAverageTeacherSalary());
            TeachingCostDTO result = new TeachingCost(courseInstance, plannedHours, allocatedHours, averageTeacherSalary).toDTO();
            dbConnection.commit();
            return result;
        } catch (Exception exception) {
            rollback(exception);
            if (exception instanceof CourseException courseException) {
                throw courseException;
            }
            throw new CourseException("Could not calculate teaching cost for " + instanceId, exception);
        }
    }

    public void addRegisteredStudents(String instanceId, int numberOfStudents) throws CourseException {
        try {
            CourseInstanceDTO courseInstanceDTO = courseInstanceDAO.findCurrentYearCourseInstance(instanceId);
            if (courseInstanceDTO == null) {
                throw new CourseException("No course instance for the current year: " + instanceId);
            }

            CourseInstance courseInstance = new CourseInstance(courseInstanceDTO);
            courseInstance.increaseRegisteredStudents(numberOfStudents);
            courseInstanceDAO.updateCourseInstance(courseInstance.toDTO());
            dbConnection.commit();
        } catch (Exception exception) {
            throw new CourseException("Could not add " + numberOfStudents + " registered students to: " + instanceId, exception);
        }
    }

    /**
     * Allocates the specified teacher to the specified teaching activity of the specified
     * course instance. The allocation is refused if the teacher then would be involved in
     * more course instances than allowed during one academic period.
     *
     * @param employmentId    The business id of the employment of the teacher.
     * @param instanceId      The business id of the course instance.
     * @param activityName    The name of the teaching activity.
     * @param allocationHours The number of raw hours to allocate.
     * @return The allocations of the course instance after the change.
     * @throws RejectedException If the teacher is involved in too many course instances.
     * @throws CourseException   If unable to allocate the teacher.
     */
    public List<AllocationDTO> allocateTeacher(int employmentId, String instanceId, String activityName, int allocationHours) throws RejectedException, CourseException {
        try {
            CourseInstanceDTO courseInstance = courseInstanceDAO.findCurrentYearCourseInstance(instanceId);
            checkTeacherIsAvailable(employmentId, courseInstance);
            PlannedActivityDTO plannedActivity = readPlannedActivity(instanceId, activityName);
            teachingActivityDAO.createAllocation(plannedActivity.plannedActivityId(), employmentId, allocationHours);
            List<AllocationDTO> allocations = teachingActivityDAO.findAllocationsByCourseInstance(instanceId);
            dbConnection.commit();
            return allocations;
        } catch (RejectedException rejected) {
            rollback(rejected);
            throw rejected;
        } catch (Exception exception) {
            throw new CourseException("Could not allocate the employee " + employmentId + " to " + activityName + " of " + instanceId, exception);
        }
    }

    private PlannedActivityDTO readPlannedActivity(String instanceId, String activityName) throws CourseDBException, CourseException {
        PlannedActivityDTO plannedActivity = teachingActivityDAO.findPlannedActivity(instanceId, activityName);
        if (plannedActivity == null) {
            throw new CourseException("The course instance " + instanceId + " has no planned activity called " + activityName);
        }
        return plannedActivity;
    }

    private void checkTeacherIsAvailable(int employmentId, CourseInstanceDTO courseInstance) throws CourseDBException, RejectedException, CourseException {
        int maxCourseInstances = policyDAO.findPolicyByName(ALLOCATION_POLICY);
        EmployeeDTO teacher = employeeDAO.findEmployeeForUpdate(employmentId);
        if (teacher == null) {
            throw new CourseException("There is no employee with the employment id: " + employmentId);
        }
        List<AllocationDTO> allocations = teachingActivityDAO.findAllocationsByTeacherAndPeriod(employmentId, courseInstance.academicYear(), courseInstance.periodName());
        TeacherLoad teacherLoad = new TeacherLoad(employmentId, allocations, maxCourseInstances);
        if (!teacherLoad.canTakeAnotherInstance(courseInstance.instanceId())) {
            throw new RejectedException("The teacher " + teacher.firstName() + " " + teacher.lastName() + " is already involved in " + teacherLoad.getNumberOfCourseInstances() + " course instances in " + courseInstance.periodName() + " " + courseInstance.academicYear() + ", which is the maximum of " + maxCourseInstances);
        }
    }

    /**
     * Removes the allocation of the specified teacher to the specified teaching activity
     * of the specified course instance.
     *
     * @param employmentId The business id of the employment of the teacher.
     * @param instanceId   The business id of the course instance.
     * @param activityName The name of the teaching activity.
     * @return The allocations of the course instance after the change.
     * @throws CourseException If unable to remove the allocation.
     */
    public List<AllocationDTO> deallocateTeacher(int employmentId, String instanceId,
                                                 String activityName) throws CourseException {
        try {
            PlannedActivityDTO plannedActivity = readPlannedActivity(instanceId, activityName);
            teachingActivityDAO.deleteAllocation(plannedActivity.plannedActivityId(), employmentId);
            List<AllocationDTO> allocations = teachingActivityDAO.findAllocationsByCourseInstance(instanceId);
            dbConnection.commit();
            return allocations;
        } catch (Exception exception) {
            throw new CourseException("Could not remove the allocation of the employee " + employmentId + " to " + activityName + " of " + instanceId, exception);
        }
    }

    public List<AllocationDTO> addTeachingActivity(String activityName, BigDecimal multiplicationFactor, String instanceId, int plannedHours, int employmentId, int allocationHours) throws RejectedException, CourseException {
        try {
            CourseInstanceDTO courseInstance = courseInstanceDAO.findCurrentYearCourseInstance(instanceId);
            if (courseInstance == null) {
                throw new CourseException("No course instance for the current year: " + instanceId);
            }
            checkTeacherIsAvailable(employmentId, courseInstance);
            teachingActivityDAO.createTeachingActivity(new TeachingActivityDTO(activityName, multiplicationFactor));
            teachingActivityDAO.createPlannedActivity(instanceId, activityName, plannedHours);
            PlannedActivityDTO plannedActivity = readPlannedActivity(instanceId, activityName);
            teachingActivityDAO.createAllocation(plannedActivity.plannedActivityId(), employmentId, allocationHours);
            List<AllocationDTO> allocations = teachingActivityDAO.findAllocationsByCourseInstance(instanceId);
            dbConnection.commit();
            return allocations;
        } catch (RejectedException rejected) {
            rollback(rejected);
            throw rejected;
        } catch (Exception exception) {
            throw new CourseException("Could not add the teaching activity " + activityName + " to " + instanceId, exception);
        }
    }

    /**
     * Reads all allocations of the specified course instance.
     *
     * @param instanceId The business id of the course instance.
     * @return The allocations of the course instance.
     * @throws CourseException If unable to read the allocations.
     */
    public List<AllocationDTO> getAllocations(String instanceId) throws CourseException {
        try {
            List<AllocationDTO> allocations = teachingActivityDAO.findAllocationsByCourseInstance(instanceId);
            dbConnection.commit();
            return allocations;
        } catch (Exception exception) {
            throw new CourseException("Could not read the allocations of: " + instanceId, exception);
        }
    }

    /** Prints the raw values used by the teaching-cost calculation for quick testing. */
    public void test() {
        try {
            System.out.println("--- CONTROLLER TEST FOR BASIC PRINTOUT ---");
            BigDecimal hours = courseInstanceDAO.findPlannedHoursByCourseInstance("2026-50000011");
            dbConnection.commit();
            System.out.println(hours);

            BigDecimal allocHours = courseInstanceDAO.findAllocatedHoursByCourseInstance("2026-50000011");
            dbConnection.commit();
            System.out.println(allocHours);

            BigDecimal salary = employeeDAO.findAverageTeacherSalary();
            dbConnection.commit();
            System.out.println(salary);

            System.out.println();
        } catch (CourseDBException | DatabaseConnectionException exception) {
            rollback(exception);
            exception.printStackTrace();
        }
    }

    private void rollback(Exception originalFailure) {
        try {
            dbConnection.rollback();
        } catch (DatabaseConnectionException rollbackFailure) {
            originalFailure.addSuppressed(rollbackFailure);
        }
    }
}

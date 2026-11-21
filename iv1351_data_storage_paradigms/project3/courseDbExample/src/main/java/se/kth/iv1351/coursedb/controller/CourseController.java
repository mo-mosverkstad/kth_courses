package se.kth.iv1351.coursedb.controller;

import java.math.BigDecimal;
import java.util.List;

import se.kth.iv1351.coursedb.dto.AllocationDTO;
import se.kth.iv1351.coursedb.dto.CourseInstanceDTO;
import se.kth.iv1351.coursedb.dto.EmployeeDTO;
import se.kth.iv1351.coursedb.dto.PlannedActivityDTO;
import se.kth.iv1351.coursedb.dto.TeachingActivityDTO;
import se.kth.iv1351.coursedb.dto.TeachingCostDTO;
import se.kth.iv1351.coursedb.integration.CourseDAO;
import se.kth.iv1351.coursedb.integration.CourseDBException;
import se.kth.iv1351.coursedb.model.Amount;
import se.kth.iv1351.coursedb.model.CourseException;
import se.kth.iv1351.coursedb.model.CourseInstance;
import se.kth.iv1351.coursedb.model.RejectedException;
import se.kth.iv1351.coursedb.model.TeacherLoad;
import se.kth.iv1351.coursedb.model.TeachingCost;

/**
 * The application's single controller. All calls from the view pass through here, and all
 * transaction boundaries are decided here. The controller contains no business rules, it
 * only calls the integration layer and the model, in the order the use case requires.
 */
public class CourseController {
    private static final String ALLOCATION_POLICY = "allocation_rule";

    private final CourseDAO courseDb;

    /**
     * Creates a new instance and connects to the course database.
     *
     * @throws CourseDBException If unable to connect to the course database.
     */
    public CourseController() throws CourseDBException {
        courseDb = new CourseDAO();
    }

    /**
     * Calculates the planned and the actual teaching cost of the specified course
     * instance.
     *
     * @param instanceId The business id of the course instance.
     * @return The planned and the actual cost.
     * @throws CourseException If unable to calculate the cost.
     */
    public TeachingCostDTO calculateTeachingCost(String instanceId) throws CourseException {
        try {
            CourseInstanceDTO courseInstance = readCourseInstance(instanceId, false);
            TeachingCostDTO cost = calculateCost(courseInstance);
            courseDb.commit();
            return cost;
        } catch (Exception exception) {
            throw new CourseException("Could not calculate the teaching cost of: "
                                      + instanceId, exception);
        }
    }

    /**
     * Increases the number of registered students of the specified course instance, and
     * calculates the teaching cost after the change. The course instance is read with a
     * lock, and the whole operation is performed in one single transaction, in order to
     * avoid the lost update anomaly.
     *
     * @param instanceId        The business id of the course instance.
     * @param numberOfStudents  The number of students to add.
     * @return The planned and the actual cost after the change.
     * @throws CourseException If unable to change the number of students.
     */
    public TeachingCostDTO addRegisteredStudents(String instanceId, int numberOfStudents)
            throws CourseException {
        try {
            CourseInstanceDTO storedCourseInstance = readCourseInstance(instanceId, true);
            CourseInstance courseInstance = new CourseInstance(storedCourseInstance);
            courseInstance.increaseRegisteredStudents(numberOfStudents);
            courseDb.updateCourseInstance(courseInstance.toDTO());
            TeachingCostDTO cost = calculateCost(courseInstance.toDTO());
            courseDb.commit();
            return cost;
        } catch (Exception exception) {
            throw new CourseException("Could not add " + numberOfStudents
                                      + " registered students to: " + instanceId, exception);
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
    public List<AllocationDTO> allocateTeacher(int employmentId, String instanceId,
                                               String activityName, int allocationHours)
            throws RejectedException, CourseException {
        try {
            CourseInstanceDTO courseInstance = readCourseInstance(instanceId, false);
            checkTeacherIsAvailable(employmentId, courseInstance);
            PlannedActivityDTO plannedActivity = readPlannedActivity(instanceId, activityName);
            courseDb.createAllocation(plannedActivity.plannedActivityId(), employmentId,
                                      allocationHours);
            List<AllocationDTO> allocations =
                    courseDb.findAllocationsByCourseInstance(instanceId);
            courseDb.commit();
            return allocations;
        } catch (RejectedException rejected) {
            rollback();
            throw rejected;
        } catch (Exception exception) {
            throw new CourseException("Could not allocate the employee " + employmentId
                                      + " to " + activityName + " of " + instanceId,
                                      exception);
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
            courseDb.deleteAllocation(plannedActivity.plannedActivityId(), employmentId);
            List<AllocationDTO> allocations =
                    courseDb.findAllocationsByCourseInstance(instanceId);
            courseDb.commit();
            return allocations;
        } catch (Exception exception) {
            throw new CourseException("Could not remove the allocation of the employee "
                                      + employmentId + " to " + activityName + " of "
                                      + instanceId, exception);
        }
    }

    /**
     * Creates a new teaching activity, plans it in the specified course instance and
     * allocates the specified teacher to it. Everything is performed in one single
     * transaction, which means that nothing is created if the teacher is involved in too
     * many course instances.
     *
     * @param activityName         The name of the new teaching activity.
     * @param multiplicationFactor The multiplication factor of the new teaching activity.
     * @param instanceId           The business id of the course instance.
     * @param plannedHours         The planned raw hours of the new activity.
     * @param employmentId         The business id of the employment of the teacher.
     * @param allocationHours      The number of raw hours to allocate.
     * @return The allocations of the course instance after the change.
     * @throws RejectedException If the teacher is involved in too many course instances.
     * @throws CourseException   If unable to create the teaching activity.
     */
    public List<AllocationDTO> addTeachingActivity(String activityName,
                                                   BigDecimal multiplicationFactor,
                                                   String instanceId, int plannedHours,
                                                   int employmentId, int allocationHours)
            throws RejectedException, CourseException {
        try {
            CourseInstanceDTO courseInstance = readCourseInstance(instanceId, false);
            checkTeacherIsAvailable(employmentId, courseInstance);
            courseDb.createTeachingActivity(
                    new TeachingActivityDTO(activityName, multiplicationFactor));
            courseDb.createPlannedActivity(instanceId, activityName, plannedHours);
            PlannedActivityDTO plannedActivity = readPlannedActivity(instanceId, activityName);
            courseDb.createAllocation(plannedActivity.plannedActivityId(), employmentId,
                                      allocationHours);
            List<AllocationDTO> allocations =
                    courseDb.findAllocationsByCourseInstance(instanceId);
            courseDb.commit();
            return allocations;
        } catch (RejectedException rejected) {
            rollback();
            throw rejected;
        } catch (Exception exception) {
            throw new CourseException("Could not add the teaching activity " + activityName
                                      + " to " + instanceId, exception);
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
            List<AllocationDTO> allocations =
                    courseDb.findAllocationsByCourseInstance(instanceId);
            courseDb.commit();
            return allocations;
        } catch (Exception exception) {
            throw new CourseException("Could not read the allocations of: " + instanceId,
                                      exception);
        }
    }

    private CourseInstanceDTO readCourseInstance(String instanceId, boolean forUpdate)
            throws CourseDBException, CourseException {
        CourseInstanceDTO courseInstance = forUpdate
                ? courseDb.findCourseInstanceForUpdate(instanceId)
                : courseDb.findCourseInstance(instanceId);
        if (courseInstance == null) {
            throw new CourseException("There is no course instance with the id: " + instanceId);
        }
        return courseInstance;
    }

    private PlannedActivityDTO readPlannedActivity(String instanceId, String activityName)
            throws CourseDBException, CourseException {
        PlannedActivityDTO plannedActivity =
                courseDb.findPlannedActivity(instanceId, activityName);
        if (plannedActivity == null) {
            throw new CourseException("The course instance " + instanceId
                                      + " has no planned activity called " + activityName);
        }
        return plannedActivity;
    }

    private TeachingCostDTO calculateCost(CourseInstanceDTO courseInstance)
            throws CourseDBException {
        String instanceId = courseInstance.instanceId();
        int plannedHours = courseDb.findPlannedHoursByCourseInstance(instanceId);
        int allocatedHours = courseDb.findAllocatedHoursByCourseInstance(instanceId);
        Amount averageSalary = new Amount(courseDb.findAverageTeacherSalary());
        return new TeachingCost(courseInstance, plannedHours, allocatedHours, averageSalary)
                .toDTO();
    }

    private void checkTeacherIsAvailable(int employmentId, CourseInstanceDTO courseInstance)
            throws CourseDBException, RejectedException, CourseException {
        int maxCourseInstances = courseDb.findPolicyByName(ALLOCATION_POLICY);
        EmployeeDTO teacher = courseDb.findEmployeeForUpdate(employmentId);
        if (teacher == null) {
            throw new CourseException("There is no employee with the employment id: "
                                      + employmentId);
        }
        List<AllocationDTO> allocations = courseDb.findAllocationsByTeacherAndPeriod(
                employmentId, courseInstance.academicYear(), courseInstance.periodName());
        TeacherLoad teacherLoad = new TeacherLoad(employmentId, allocations, maxCourseInstances);
        if (!teacherLoad.canTakeAnotherInstance(courseInstance.instanceId())) {
            throw new RejectedException("The teacher " + teacher.firstName() + " "
                                        + teacher.lastName() + " is already involved in "
                                        + teacherLoad.getNumberOfCourseInstances()
                                        + " course instances in " + courseInstance.periodName()
                                        + " " + courseInstance.academicYear()
                                        + ", which is the maximum of " + maxCourseInstances);
        }
    }

    private void rollback() throws CourseException {
        try {
            courseDb.rollback();
        } catch (CourseDBException exception) {
            throw new CourseException("Could not roll back the transaction.", exception);
        }
    }
}

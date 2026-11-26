package se.kth.iv1351.controller;

import java.math.BigDecimal;

import se.kth.iv1351.config.Config;
import se.kth.iv1351.dto.CourseInstanceDTO;
import se.kth.iv1351.dto.TeachingCostDTO;
import se.kth.iv1351.integration.CourseDBException;
import se.kth.iv1351.integration.CourseInstanceDAO;
import se.kth.iv1351.integration.DatabaseConnection;
import se.kth.iv1351.integration.DatabaseConnectionException;
import se.kth.iv1351.integration.EmployeeDAO;
import se.kth.iv1351.model.Amount;
import se.kth.iv1351.model.CourseException;
import se.kth.iv1351.model.TeachingCost;

/** Coordinates the teaching-cost use case and owns its transaction boundary. */
public class CourseDBController {
    private final DatabaseConnection dbConnection;
    private final CourseInstanceDAO courseInstanceDAO;
    private final EmployeeDAO employeeDAO;

    public CourseDBController() {
        try {
            dbConnection = new DatabaseConnection(Config.DATABASE_NAME, Config.USERNAME,
                                                  Config.PASSWORD);
            courseInstanceDAO = new CourseInstanceDAO(dbConnection);
            employeeDAO = new EmployeeDAO(dbConnection);
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
            CourseInstanceDTO courseInstance =
                    courseInstanceDAO.findCurrentYearCourseInstance(instanceId);
            if (courseInstance == null) {
                throw new CourseException("No course instance for the current year: " + instanceId);
            }

            int plannedHours = courseInstanceDAO.findPlannedHoursByCourseInstance(instanceId)
                    .intValueExact();
            int allocatedHours = courseInstanceDAO.findAllocatedHoursByCourseInstance(instanceId)
                    .intValueExact();
            Amount averageTeacherSalary = new Amount(employeeDAO.findAverageTeacherSalary());
            TeachingCostDTO result = new TeachingCost(courseInstance, plannedHours,
                                                      allocatedHours, averageTeacherSalary)
                    .toDTO();
            dbConnection.commit();
            return result;
        } catch (Exception exception) {
            rollback(exception);
            if (exception instanceof CourseException courseException) {
                throw courseException;
            }
            throw new CourseException("Could not calculate teaching cost for " + instanceId,
                                      exception);
        }
    }

    /** Prints the raw values used by the teaching-cost calculation for quick testing. */
    public void test() {
        try {
            BigDecimal hours =
                    courseInstanceDAO.findPlannedHoursByCourseInstance("2026-50000011");
            dbConnection.commit();
            System.out.println(hours);

            BigDecimal allocHours =
                    courseInstanceDAO.findAllocatedHoursByCourseInstance("2026-50000011");
            dbConnection.commit();
            System.out.println(allocHours);

            BigDecimal salary = employeeDAO.findAverageTeacherSalary();
            dbConnection.commit();
            System.out.println(salary);

            TeachingCostDTO teachingCost = calculateTeachingCost("2026-50000011");
            System.out.println(teachingCost);
        } catch (CourseException | CourseDBException | DatabaseConnectionException exception) {
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

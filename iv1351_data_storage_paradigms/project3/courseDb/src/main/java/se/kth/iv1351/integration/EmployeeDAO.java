package se.kth.iv1351.integration;

import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

import se.kth.iv1351.dto.EmployeeDTO;

public final class EmployeeDAO extends AbstractDAO {
    private PreparedStatement averageSalaryStatement;
    private PreparedStatement findEmployeeForUpdateStmt;
    
    public EmployeeDAO(DatabaseConnection databaseConnection) throws CourseDBException {
        super(databaseConnection);
    }

    public BigDecimal findAverageTeacherSalary() throws CourseDBException{
        String failureMsg = "Could not find average teacher salary";
        ResultSet result = null;
        try{
            result = averageSalaryStatement.executeQuery();
            if (result.next()){
                return result.getBigDecimal("average_salary");
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

    public EmployeeDTO findEmployeeForUpdate(int employmentId) throws CourseDBException {
        String failureMsg = "Could not read the employee: " + employmentId;
        ResultSet result = null;
        try {
            findEmployeeForUpdateStmt.setInt(1, employmentId);
            result = findEmployeeForUpdateStmt.executeQuery();
            if (result.next()) {
                return new EmployeeDTO(
                    result.getInt("employment_id"),
                    result.getString("first_name"),
                    result.getString("last_name"),
                    result.getString("job_title_name")
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

    protected void prepareStatements() throws SQLException{
        Connection connection = databaseConnection.getConnection();
        averageSalaryStatement = connection.prepareStatement("""
            SELECT 
                AVG(latest.salary) AS average_salary
            FROM (
                SELECT DISTINCT ON (employee_salary.employee_id) employee_salary.salary
                FROM employee_salary
                ORDER BY employee_salary.employee_id, employee_salary.valid_from DESC
            ) AS latest;
        """);
        findEmployeeForUpdateStmt = connection.prepareStatement("""
            SELECT employee.employment_id,
                   person.first_name,
                   person.last_name,
                   job_title.job_title_name
            FROM employee
            INNER JOIN person ON person.id = employee.person_id
            INNER JOIN job_title ON job_title.id = employee.job_title_id
            WHERE employee.employment_id = ?
            FOR NO KEY UPDATE OF employee
        """);
    }
}

package se.kth.iv1351.integration;

import java.math.BigDecimal;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

public class EmployeeDAO extends AbstractDAO {
    private PreparedStatement averageSalaryStatement;
    
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
    }
}

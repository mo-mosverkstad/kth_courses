package se.kth.iv1351.integration;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

public final class PolicyDAO extends AbstractDAO {
    public PreparedStatement findPolicyStmt;

    public PolicyDAO(DatabaseConnection databaseConnection) throws CourseDBException {
        super(databaseConnection);
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
            throw new CourseDBException(failureMsg, null);
        }
        catch (SQLException exception) {
            throw new CourseDBException(failureMsg, exception);
        }
        finally {
            closeResultSet(failureMsg, result);
        }
    }

    @Override
    protected void prepareStatements() throws SQLException {
        Connection connection = databaseConnection.getConnection();
        findPolicyStmt = connection.prepareStatement("""
            SELECT policy.policy_value
            FROM policy
            WHERE policy.policy_name = ?
        """);
    }
    
}

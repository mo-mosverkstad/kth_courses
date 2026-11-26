package se.kth.iv1351.integration;

import java.sql.ResultSet;
import java.sql.SQLException;

public abstract class AbstractDAO {
    protected final DatabaseConnection databaseConnection;

    public AbstractDAO(DatabaseConnection databaseConnection) throws CourseDBException{
        this.databaseConnection = databaseConnection;
        try{
            prepareStatements();
        }
        catch (SQLException sqlException){
            throw new CourseDBException("Could not prepare the statements of "
                                        + getClass().getSimpleName(), sqlException);
        }
    }

    protected void closeResultSet(String failureMsg, ResultSet result) throws CourseDBException {
        if (result == null) {
            return;
        }
        try {
            result.close();
        } catch (Exception exception) {
            throw new CourseDBException(failureMsg + " Could not close result set.", exception);
        }
    }

    abstract protected void prepareStatements() throws SQLException;
}

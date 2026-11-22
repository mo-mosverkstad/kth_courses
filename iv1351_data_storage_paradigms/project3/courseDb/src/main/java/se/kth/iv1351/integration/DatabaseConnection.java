package se.kth.iv1351.integration;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

public class DatabaseConnection {
    private static final String URL_PREFIX = "jdbc:postgresql://localhost:5432/";

    private Connection connection;

    public DatabaseConnection(String databaseName, String user, String password)
            throws DatabaseConnectionException{
        try{
            connect(databaseName, user, password);
        }
        catch (SQLException exception){
            throw new DatabaseConnectionException("Could not connect to the database: "
                                                  + databaseName, exception);
        }
    }

    private void connect(String databaseName, String user, String password)
            throws SQLException {
        connection = DriverManager.getConnection(URL_PREFIX + databaseName, user, password);
        connection.setAutoCommit(false);
    }

    Connection getConnection(){
        return connection;
    }

    public void commit() throws DatabaseConnectionException {
        try{
            connection.commit();
        }
        catch (SQLException exception){
            throw new DatabaseConnectionException("Could not commit the transaction.",
                                                  exception);
        }
    }

    public void rollback() throws DatabaseConnectionException {
        try{
            connection.rollback();
        }
        catch (SQLException exception){
            throw new DatabaseConnectionException("Could not roll back the transaction.",
                                                  exception);
        }
    }
}

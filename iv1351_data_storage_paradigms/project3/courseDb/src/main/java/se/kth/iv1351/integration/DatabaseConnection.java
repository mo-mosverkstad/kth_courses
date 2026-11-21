package se.kth.iv1351.integration;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

import se.kth.iv1351.integration.DatabaseConnectionException;

public class DatabaseConnection {
    private Connection connection;
    public DatabaseConnection(String user, String password) throws DatabaseConnectionException{
        try{
            connect(user, password);
        }
        catch (ClassNotFoundException | SQLException exception){
            throw new DatabaseConnectionException(exception);
        }
    }

    private void connect(String user, String password) throws ClassNotFoundException, SQLException {
        connection = DriverManager.getConnection("jdbc:postgresql://localhost:5432/bankdb",
                user, password);
        // connection =
        // DriverManager.getConnection("jdbc:mysql://localhost:3306/bankdb",
        // "mysql", "mysql");
        connection.setAutoCommit(false);
    }

    public Connection getConnection(){
        return connection;
    }

}

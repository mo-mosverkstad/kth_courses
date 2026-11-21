package se.kth.iv1351.integration;

public class DatabaseConnectionException extends Exception {
    private Exception exception;
    public DatabaseConnectionException(Exception exception){
        this.exception = exception;
    }

    public Exception getException(){
        return exception;
    }

    @Override
    public String toString(){
        return String.format("Database exception: %s", exception.toString());
    }
}

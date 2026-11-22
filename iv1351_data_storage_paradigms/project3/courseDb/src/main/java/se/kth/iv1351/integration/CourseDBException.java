package se.kth.iv1351.integration;

public class CourseDBException extends Exception {
    public CourseDBException(String message){
        super(message);
    }

    public CourseDBException(String message, Throwable cause){
        super(message, cause);
    }
}

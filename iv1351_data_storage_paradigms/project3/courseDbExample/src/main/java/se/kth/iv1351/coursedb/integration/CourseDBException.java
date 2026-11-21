package se.kth.iv1351.coursedb.integration;

/**
 * Thrown when a call to the course database fails.
 */
public class CourseDBException extends Exception {
    /**
     * Creates a new instance with the specified message.
     *
     * @param message A message describing what went wrong.
     */
    public CourseDBException(String message) {
        super(message);
    }

    /**
     * Creates a new instance with the specified message and cause.
     *
     * @param message A message describing what went wrong.
     * @param cause   The exception that caused this exception to be thrown.
     */
    public CourseDBException(String message, Throwable cause) {
        super(message, cause);
    }
}

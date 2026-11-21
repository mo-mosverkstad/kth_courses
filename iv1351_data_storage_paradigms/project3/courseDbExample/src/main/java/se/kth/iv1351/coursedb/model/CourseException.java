package se.kth.iv1351.coursedb.model;

/**
 * Thrown when an operation on the course database fails for some other reason than that a
 * business rule was broken.
 */
public class CourseException extends Exception {
    /**
     * Creates a new instance with the specified message.
     *
     * @param message A message describing what went wrong.
     */
    public CourseException(String message) {
        super(message);
    }

    /**
     * Creates a new instance with the specified message and cause.
     *
     * @param message A message describing what went wrong.
     * @param cause   The exception that caused this exception to be thrown.
     */
    public CourseException(String message, Throwable cause) {
        super(message, cause);
    }
}

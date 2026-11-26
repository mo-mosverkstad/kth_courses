package se.kth.iv1351.model;

/**
 * Thrown when an operation is refused because it would break a business rule.
 */
public class RejectedException extends Exception {
    /**
     * Creates a new instance with the specified message.
     *
     * @param message A message describing why the operation was refused.
     */
    public RejectedException(String message) {
        super(message);
    }

    /**
     * Creates a new instance with the specified message and cause.
     *
     * @param message A message describing why the operation was refused.
     * @param cause   The exception that caused this exception to be thrown.
     */
    public RejectedException(String message, Throwable cause) {
        super(message, cause);
    }
}

package se.kth.iv1351.model;

import java.math.BigDecimal;
import java.math.RoundingMode;

/**
 * An amount of money in SEK. Instances of this class are immutable, every operation
 * returns a new instance instead of changing the existing one. The amount is stored as a
 * <code>BigDecimal</code>, since money must not be stored in a floating point type.
 */
public final class Amount {
    private static final int SCALE = 2;
    private static final BigDecimal THOUSAND = new BigDecimal("1000");

    /**
     * The amount zero.
     */
    public static final Amount ZERO = new Amount(BigDecimal.ZERO);

    private final BigDecimal amount;

    /**
     * Creates a new instance representing the specified amount.
     *
     * @param amount The amount in SEK.
     */
    public Amount(BigDecimal amount) {
        this.amount = amount.setScale(SCALE, RoundingMode.HALF_UP);
    }

    /**
     * Creates a new instance representing the specified amount.
     *
     * @param amount The amount in whole SEK.
     */
    public Amount(long amount) {
        this(BigDecimal.valueOf(amount));
    }

    /**
     * Adds the specified amount to this amount.
     *
     * @param other The amount to add.
     * @return A new instance representing the sum.
     */
    public Amount plus(Amount other) {
        return new Amount(amount.add(other.amount));
    }

    /**
     * Subtracts the specified amount from this amount.
     *
     * @param other The amount to subtract.
     * @return A new instance representing the difference.
     */
    public Amount minus(Amount other) {
        return new Amount(amount.subtract(other.amount));
    }

    /**
     * Multiplies this amount with the specified factor.
     *
     * @param factor The factor to multiply with.
     * @return A new instance representing the product.
     */
    public Amount multiply(int factor) {
        return new Amount(amount.multiply(BigDecimal.valueOf(factor)));
    }

    /**
     * Multiplies this amount with the specified factor.
     *
     * @param factor The factor to multiply with.
     * @return A new instance representing the product.
     */
    public Amount multiply(BigDecimal factor) {
        return new Amount(amount.multiply(factor));
    }

    /**
     * Divides this amount by the specified divisor.
     *
     * @param divisor The divisor to divide by.
     * @return A new instance representing the quotient.
     */
    public Amount divide(int divisor) {
        return new Amount(amount.divide(BigDecimal.valueOf(divisor), SCALE,
                                        RoundingMode.HALF_UP));
    }

    /**
     * @return The amount in SEK.
     */
    public BigDecimal getAmount() {
        return amount;
    }

    /**
     * @return The amount in thousands of SEK, rounded to whole KSEK.
     */
    public BigDecimal inThousands() {
        return amount.divide(THOUSAND, 0, RoundingMode.HALF_UP);
    }

    /**
     * Two amounts are equal if they represent the same amount of money.
     *
     * @param other The object to compare with.
     * @return <code>true</code> if the specified object represents the same amount,
     *         <code>false</code> otherwise.
     */
    @Override
    public boolean equals(Object other) {
        if (this == other) {
            return true;
        }
        if (!(other instanceof Amount)) {
            return false;
        }
        Amount otherAmount = (Amount) other;
        return amount.compareTo(otherAmount.amount) == 0;
    }

    /**
     * @return A hash code consistent with <code>equals</code>.
     */
    @Override
    public int hashCode() {
        return amount.stripTrailingZeros().hashCode();
    }

    /**
     * @return A string representation of this amount.
     */
    @Override
    public String toString() {
        return amount.toPlainString();
    }
}

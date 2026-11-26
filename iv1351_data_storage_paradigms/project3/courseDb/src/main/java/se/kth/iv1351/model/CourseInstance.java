package se.kth.iv1351.model;

import java.math.BigDecimal;

import se.kth.iv1351.dto.CourseInstanceDTO;

/**
 * One instance of a course, given in one academic period. This class owns the rules for
 * changing the number of registered students.
 */
public class CourseInstance {
    private final String instanceId;
    private final String courseCode;
    private final String courseName;
    private final String periodName;
    private final int academicYear;
    private final BigDecimal hp;
    private int numStudents;

    /**
     * Creates a new instance with the state of the specified DTO.
     *
     * @param courseInstance The course instance read from the database.
     */
    public CourseInstance(CourseInstanceDTO courseInstance) {
        this.instanceId = courseInstance.instanceId();
        this.courseCode = courseInstance.courseCode();
        this.courseName = courseInstance.courseName();
        this.periodName = courseInstance.periodName();
        this.academicYear = courseInstance.academicYear();
        this.hp = courseInstance.hp();
        this.numStudents = courseInstance.numStudents();
    }

    /**
     * Increases the number of registered students by the specified number.
     *
     * @param increase The number of students to add, which must not be negative.
     * @throws RejectedException If the specified number is negative.
     */
    public void increaseRegisteredStudents(int increase) throws RejectedException {
        if (increase < 0) {
            throw new RejectedException("Tried to increase the number of registered "
                                        + "students by a negative number, illegal value: "
                                        + increase + ", course instance: " + this);
        }
        numStudents = numStudents + increase;
    }

    /**
     * @return The business id of the course instance.
     */
    public String getInstanceId() {
        return instanceId;
    }

    /**
     * @return The number of registered students.
     */
    public int getNumStudents() {
        return numStudents;
    }

    /**
     * @return A read-only view of the current state of this course instance.
     */
    public CourseInstanceDTO toDTO() {
        return new CourseInstanceDTO(instanceId, courseCode, courseName, periodName,
                                     academicYear, hp, numStudents);
    }

    /**
     * @return A string representation of all fields in this object.
     */
    @Override
    public String toString() {
        return toDTO().toString();
    }
}

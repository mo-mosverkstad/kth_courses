package se.kth.iv1351.coursedb.dto;

/**
 * An immutable read-only view of one employee. The data is collected by joining the
 * tables <code>employee</code>, <code>person</code> and <code>job_title</code>.
 *
 * @param employmentId The business id of the employment.
 * @param firstName    The first name of the employee.
 * @param lastName     The last name of the employee.
 * @param jobTitle     The name of the job title of the employee.
 */
public record EmployeeDTO(int employmentId, String firstName, String lastName,
                          String jobTitle) {
}

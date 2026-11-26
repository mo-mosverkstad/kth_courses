package se.kth.iv1351.model;

import java.util.Collections;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

import se.kth.iv1351.dto.AllocationDTO;

/**
 * The teaching load of one teacher during one academic period. This class owns the rule
 * that a teacher must not be involved in more than a certain number of course instances
 * in one academic period.
 * <p>
 * The rule counts course instances and not allocations, which means that a teacher who is
 * allocated to several teaching activities inside the same course instance still occupies
 * only one of the allowed course instances.
 */
public class TeacherLoad {
    private final int employmentId;
    private final int maxCourseInstances;
    private final Set<String> occupiedInstanceIds = new HashSet<>();

    /**
     * Creates a new instance from the allocations of one teacher. The specified
     * allocations must all belong to the same academic period, which is the responsibility
     * of the caller.
     *
     * @param employmentId       The business id of the employment of the teacher.
     * @param allocations        All allocations the teacher has in the academic period.
     * @param maxCourseInstances The maximum number of course instances the teacher is
     *                           allowed to be involved in during one academic period.
     */
    public TeacherLoad(int employmentId, List<AllocationDTO> allocations,
                       int maxCourseInstances) {
        this.employmentId = employmentId;
        this.maxCourseInstances = maxCourseInstances;
        for (AllocationDTO allocation : allocations) {
            occupiedInstanceIds.add(allocation.instanceId());
        }
    }

    /**
     * Decides whether the teacher is allowed to be allocated to an activity in the
     * specified course instance. The teacher is allowed either if the specified course
     * instance is already occupied, since no further course instance is then taken, or if
     * the number of occupied course instances is below the maximum.
     *
     * @param instanceId The business id of the course instance to allocate to.
     * @return <code>true</code> if the allocation is allowed, <code>false</code> otherwise.
     */
    public boolean canTakeAnotherInstance(String instanceId) {
        if (isAllocatedTo(instanceId)) {
            return true;
        }
        return occupiedInstanceIds.size() < maxCourseInstances;
    }

    /**
     * Decides whether the teacher already is allocated to some activity in the specified
     * course instance.
     *
     * @param instanceId The business id of the course instance.
     * @return <code>true</code> if the teacher occupies the course instance,
     *         <code>false</code> otherwise.
     */
    public boolean isAllocatedTo(String instanceId) {
        return occupiedInstanceIds.contains(instanceId);
    }

    /**
     * @return The business id of the employment of the teacher.
     */
    public int getEmploymentId() {
        return employmentId;
    }

    /**
     * @return The maximum number of course instances allowed in one academic period.
     */
    public int getMaxCourseInstances() {
        return maxCourseInstances;
    }

    /**
     * @return The number of course instances the teacher currently occupies.
     */
    public int getNumberOfCourseInstances() {
        return occupiedInstanceIds.size();
    }

    /**
     * @return The business ids of the course instances the teacher currently occupies.
     */
    public Set<String> getOccupiedInstanceIds() {
        return Collections.unmodifiableSet(occupiedInstanceIds);
    }

    /**
     * @return A string representation of all fields in this object.
     */
    @Override
    public String toString() {
        StringBuilder stringRepresentation = new StringBuilder();
        stringRepresentation.append("TeacherLoad: [");
        stringRepresentation.append("employment id: ");
        stringRepresentation.append(employmentId);
        stringRepresentation.append(", course instances: ");
        stringRepresentation.append(occupiedInstanceIds.size());
        stringRepresentation.append(" of ");
        stringRepresentation.append(maxCourseInstances);
        stringRepresentation.append(", occupied course instances: ");
        stringRepresentation.append(occupiedInstanceIds);
        stringRepresentation.append("]");
        return stringRepresentation.toString();
    }
}

package com.example.stark_group_vms.repository;

import com.example.stark_group_vms.entity.Vehicle;
import com.example.stark_group_vms.enums.VehicleStatus;
import java.util.List;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

@Repository
public interface VehicleRepository extends JpaRepository<Vehicle, Long> {

    /** The text match shared by the list and the counts, so their numbers always agree. */
    String MATCHES_Q = """
            (:q is null
             or lower(v.vehicleNumber) like :q escape '!'
             or lower(v.brand) like :q escape '!'
             or lower(v.model) like :q escape '!'
             or lower(coalesce(v.company, '')) like :q escape '!'
             or lower(coalesce(v.driverName, '')) like :q escape '!')
            """;

    boolean existsByVehicleNumberIgnoreCase(String vehicleNumber);

    boolean existsByVehicleNumberIgnoreCaseAndIdNot(String vehicleNumber, Long id);

    /** {@code q} is a ready LIKE pattern (lower case, wildcards escaped) or null for no text filter. */
    @Query("select v from Vehicle v where " + MATCHES_Q + " and (:status is null or v.status = :status)")
    Page<Vehicle> search(@Param("q") String q, @Param("status") VehicleStatus status, Pageable pageable);

    /** Rows of [status, count] for vehicles matching {@code q}. */
    @Query("select v.status, count(v) from Vehicle v where " + MATCHES_Q + " group by v.status")
    List<Object[]> countByStatus(@Param("q") String q);
}

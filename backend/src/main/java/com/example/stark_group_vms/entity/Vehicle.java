package com.example.stark_group_vms.entity;

import com.example.stark_group_vms.enums.FuelType;
import com.example.stark_group_vms.enums.VehicleStatus;
import com.example.stark_group_vms.enums.VehicleType;
import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.hibernate.annotations.CreationTimestamp;
import org.hibernate.annotations.UpdateTimestamp;

import java.time.LocalDateTime;

/**
 * Persistence only. Input validation lives in VehicleRequest; the vehicle number's
 * uniqueness is enforced by the unique key below (case-insensitive under MySQL's default
 * utf8mb4_0900_ai_ci collation, and numbers are stored upper case anyway).
 */
@Getter
@Setter
@NoArgsConstructor
@Entity
@Table(name = "vehicles")
public class Vehicle {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true)
    private String vehicleNumber;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private VehicleType vehicleType;

    @Column(length = 100)
    private String company;

    @Column(nullable = false)
    private String brand;

    @Column(nullable = false)
    private String model;

    private Integer manufacturingYear;

    private String color;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private FuelType fuelType;

    private Integer seatingCapacity;

    private String driverName;

    private String driverPhone;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private VehicleStatus status = VehicleStatus.AVAILABLE;

    @Setter(AccessLevel.NONE)
    @CreationTimestamp
    @Column(updatable = false)
    private LocalDateTime createdAt;

    @Setter(AccessLevel.NONE)
    @UpdateTimestamp
    private LocalDateTime updatedAt;
}

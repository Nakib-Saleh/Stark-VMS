package com.example.stark_group_vms.dto;

import com.example.stark_group_vms.enums.FuelType;
import com.example.stark_group_vms.enums.VehicleStatus;
import com.example.stark_group_vms.enums.VehicleType;
import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import jakarta.validation.constraints.Size;

/**
 * What a client may send to create or update a vehicle. Server-owned fields
 * (id, createdAt, updatedAt) are deliberately absent, so a client can't set them.
 * "Not later than next year" for manufacturingYear is checked in VehicleService.
 */
public record VehicleRequest(
        @NotBlank(message = "Vehicle number is required")
        @Size(max = 50, message = "Vehicle number must be 50 characters or fewer")
        String vehicleNumber,

        @NotNull(message = "Vehicle type is required")
        VehicleType vehicleType,

        @Size(max = 100, message = "Company must be 100 characters or fewer")
        String company,

        @NotBlank(message = "Brand is required")
        @Size(max = 100, message = "Brand must be 100 characters or fewer")
        String brand,

        @NotBlank(message = "Model is required")
        @Size(max = 100, message = "Model must be 100 characters or fewer")
        String model,

        @Min(value = 1900, message = "Manufacturing year must be 1900 or later")
        Integer manufacturingYear,

        @Size(max = 50, message = "Colour must be 50 characters or fewer")
        String color,

        @NotNull(message = "Fuel type is required")
        FuelType fuelType,

        @Positive(message = "Seating capacity must be at least 1")
        @Max(value = 100, message = "Seating capacity must be 100 or fewer")
        Integer seatingCapacity,

        @Size(max = 100, message = "Driver name must be 100 characters or fewer")
        String driverName,

        @Size(max = 20, message = "Driver phone must be 20 characters or fewer")
        String driverPhone,

        VehicleStatus status
) {
}

package com.example.stark_group_vms.service;

import com.example.stark_group_vms.dto.VehicleRequest;
import com.example.stark_group_vms.dto.VehicleResponse;
import com.example.stark_group_vms.entity.Vehicle;
import com.example.stark_group_vms.enums.VehicleStatus;
import com.example.stark_group_vms.exception.DuplicateResourceException;
import com.example.stark_group_vms.exception.InvalidRequestException;
import com.example.stark_group_vms.exception.ResourceNotFoundException;
import com.example.stark_group_vms.repository.VehicleRepository;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Year;
import java.util.Arrays;
import java.util.EnumMap;
import java.util.Locale;
import java.util.Map;

@Service
public class VehicleService {

    /** Largest page a client may ask for (STACK.md: list endpoints cap size). */
    public static final int MAX_PAGE_SIZE = 100;

    private final VehicleRepository vehicleRepository;

    public VehicleService(VehicleRepository vehicleRepository) {
        this.vehicleRepository = vehicleRepository;
    }

    /** Longest search text accepted. */
    public static final int MAX_QUERY_LENGTH = 100;

    @Transactional(readOnly = true)
    public Page<VehicleResponse> getVehicles(int page, int size, String q, String status) {
        if (page < 0) {
            throw new InvalidRequestException("Page number can't be negative");
        }
        if (size < 1 || size > MAX_PAGE_SIZE) {
            throw new InvalidRequestException("Page size must be between 1 and " + MAX_PAGE_SIZE);
        }
        Pageable pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "id"));
        return vehicleRepository.search(likePattern(q), parseStatus(status), pageable).map(VehicleResponse::from);
    }

    /** How many vehicles matching {@code q} are in each status; every status is present, zero included. */
    @Transactional(readOnly = true)
    public Map<VehicleStatus, Long> countByStatus(String q) {
        Map<VehicleStatus, Long> counts = new EnumMap<>(VehicleStatus.class);
        for (VehicleStatus s : VehicleStatus.values()) {
            counts.put(s, 0L);
        }
        for (Object[] row : vehicleRepository.countByStatus(likePattern(q))) {
            if (row[0] != null) {
                counts.put((VehicleStatus) row[0], (Long) row[1]);
            }
        }
        return counts;
    }

    /** Null for no filter; otherwise a lower-case "contains" pattern with LIKE wildcards escaped. */
    private static String likePattern(String q) {
        if (q == null || q.isBlank()) {
            return null;
        }
        String text = q.trim();
        if (text.length() > MAX_QUERY_LENGTH) {
            String message = "Search text must be " + MAX_QUERY_LENGTH + " characters or fewer";
            throw new InvalidRequestException(message, Map.of("q", message));
        }
        String escaped = text.toLowerCase(Locale.ROOT)
                .replace("!", "!!").replace("%", "!%").replace("_", "!_");
        return "%" + escaped + "%";
    }

    private static VehicleStatus parseStatus(String status) {
        if (status == null || status.isBlank()) {
            return null;
        }
        try {
            return VehicleStatus.valueOf(status.trim().toUpperCase(Locale.ROOT));
        } catch (IllegalArgumentException e) {
            String message = "Status must be one of " + Arrays.toString(VehicleStatus.values());
            throw new InvalidRequestException(message, Map.of("status", message));
        }
    }

    @Transactional(readOnly = true)
    public VehicleResponse getVehicleById(Long id) {
        return VehicleResponse.from(findEntityById(id));
    }

    @Transactional
    public VehicleResponse createVehicle(VehicleRequest request) {
        String number = normalizeNumber(request.vehicleNumber());
        if (vehicleRepository.existsByVehicleNumberIgnoreCase(number)) {
            throw duplicate(number);
        }
        Vehicle vehicle = new Vehicle();
        apply(vehicle, request, number);
        if (vehicle.getStatus() == null) {
            vehicle.setStatus(VehicleStatus.AVAILABLE);
        }
        return VehicleResponse.from(vehicleRepository.save(vehicle));
    }

    @Transactional
    public VehicleResponse updateVehicle(Long id, VehicleRequest request) {
        Vehicle existing = findEntityById(id);
        String number = normalizeNumber(request.vehicleNumber());
        if (vehicleRepository.existsByVehicleNumberIgnoreCaseAndIdNot(number, id)) {
            throw duplicate(number);
        }
        VehicleStatus keepStatus = existing.getStatus();
        apply(existing, request, number);
        if (existing.getStatus() == null) {
            existing.setStatus(keepStatus);
        }
        return VehicleResponse.from(vehicleRepository.save(existing));
    }

    @Transactional
    public void deleteVehicle(Long id) {
        vehicleRepository.delete(findEntityById(id));
    }

    private void apply(Vehicle vehicle, VehicleRequest request, String number) {
        Integer year = request.manufacturingYear();
        int latestYear = Year.now().getValue() + 1;
        if (year != null && year > latestYear) {
            String message = "Manufacturing year can't be later than " + latestYear;
            throw new InvalidRequestException(message, Map.of("manufacturingYear", message));
        }
        vehicle.setVehicleNumber(number);
        vehicle.setVehicleType(request.vehicleType());
        vehicle.setCompany(blankToNull(request.company()));
        vehicle.setBrand(request.brand().trim());
        vehicle.setModel(request.model().trim());
        vehicle.setManufacturingYear(year);
        vehicle.setColor(blankToNull(request.color()));
        vehicle.setFuelType(request.fuelType());
        vehicle.setSeatingCapacity(request.seatingCapacity());
        vehicle.setDriverName(blankToNull(request.driverName()));
        vehicle.setDriverPhone(blankToNull(request.driverPhone()));
        vehicle.setStatus(request.status());
    }

    /** Plates are compared and stored trimmed, single-spaced and upper case. */
    private static String normalizeNumber(String raw) {
        return raw.trim().replaceAll("\\s+", " ").toUpperCase(Locale.ROOT);
    }

    private static String blankToNull(String value) {
        return value == null || value.isBlank() ? null : value.trim();
    }

    private static DuplicateResourceException duplicate(String number) {
        return new DuplicateResourceException("vehicleNumber", number + " is already registered");
    }

    private Vehicle findEntityById(Long id) {
        return vehicleRepository.findById(id)
                .orElseThrow(() -> new ResourceNotFoundException("Vehicle not found with id: " + id));
    }
}

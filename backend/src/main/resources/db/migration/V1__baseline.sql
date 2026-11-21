-- Baseline (ADR-0007): the two tables exactly as Hibernate's ddl-auto=update had built them
-- by Phase 7, with readable names for the unique keys. Never edit this file once it has run;
-- add V2__... for any change.

CREATE TABLE vehicles (
    id                 BIGINT       NOT NULL AUTO_INCREMENT,
    brand              VARCHAR(255) NOT NULL,
    color              VARCHAR(255) DEFAULT NULL,
    created_at         DATETIME(6)  NOT NULL,
    driver_name        VARCHAR(255) DEFAULT NULL,
    driver_phone       VARCHAR(255) DEFAULT NULL,
    fuel_type          ENUM('CNG','DIESEL','ELECTRIC','HYBRID','LPG','OCTANE','PETROL') NOT NULL,
    manufacturing_year INT          DEFAULT NULL,
    model              VARCHAR(255) NOT NULL,
    seating_capacity   INT          DEFAULT NULL,
    status             ENUM('AVAILABLE','INACTIVE','IN_USE','MAINTENANCE') NOT NULL,
    updated_at         DATETIME(6)  NOT NULL,
    vehicle_number     VARCHAR(255) NOT NULL,
    vehicle_type       ENUM('BUS','CAR','MICROBUS','MOTORCYCLE','PICKUP','SUV','TRUCK','VAN') NOT NULL,
    company            VARCHAR(100) DEFAULT NULL,
    PRIMARY KEY (id),
    -- Case-insensitive through the table collation; the service also stores numbers upper case.
    CONSTRAINT uk_vehicles_vehicle_number UNIQUE (vehicle_number),
    CONSTRAINT ck_vehicles_manufacturing_year CHECK (manufacturing_year >= 1900)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

CREATE TABLE users (
    id            BIGINT       NOT NULL AUTO_INCREMENT,
    created_at    DATETIME(6)  NOT NULL,
    password_hash VARCHAR(100) NOT NULL,
    username      VARCHAR(50)  NOT NULL,
    PRIMARY KEY (id),
    CONSTRAINT uk_users_username UNIQUE (username)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- =========================================================
-- POLAR COMMAND — Core Database Schema
-- PostgreSQL 15+
-- =========================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- =========================================================
-- 1. USERS & ROLES
-- =========================================================

CREATE TABLE roles (
    id              SERIAL PRIMARY KEY,
    name            VARCHAR(50) UNIQUE NOT NULL,
    description     VARCHAR(255)
);

CREATE TABLE users (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    full_name       VARCHAR(150) NOT NULL,
    email           VARCHAR(150) UNIQUE NOT NULL,
    phone           VARCHAR(30),
    password_hash   VARCHAR(255) NOT NULL,
    role_id         INTEGER NOT NULL REFERENCES roles(id),
    organization    VARCHAR(150),
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role_id);

CREATE TABLE refresh_tokens (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token           VARCHAR(500) UNIQUE NOT NULL,
    expires_at      TIMESTAMPTZ NOT NULL,
    revoked         BOOLEAN NOT NULL DEFAULT FALSE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_refresh_token_user ON refresh_tokens(user_id);

-- =========================================================
-- 2. LOCATIONS (shared reference table for map + movement)
-- =========================================================

CREATE TABLE locations (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name            VARCHAR(150) NOT NULL,
    type            VARCHAR(30) NOT NULL,
    latitude        DOUBLE PRECISION NOT NULL,
    longitude       DOUBLE PRECISION NOT NULL,
    description     VARCHAR(255),
    is_simulated    BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_locations_type ON locations(type);

-- =========================================================
-- 3. EXPEDITIONS
-- =========================================================

CREATE TABLE expeditions (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    expedition_code     VARCHAR(50) UNIQUE NOT NULL,
    name                VARCHAR(200) NOT NULL,
    year                INTEGER NOT NULL,
    start_date          DATE NOT NULL,
    end_date            DATE,
    destination         VARCHAR(150),
    research_station_id UUID REFERENCES locations(id),
    leader_id           UUID REFERENCES users(id),
    status              VARCHAR(20) NOT NULL DEFAULT 'PLANNED',
    description         TEXT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_expeditions_status ON expeditions(status);
CREATE INDEX idx_expeditions_year ON expeditions(year);

-- =========================================================
-- 4. PERSONNEL
-- =========================================================

CREATE TABLE personnel (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    personnel_code      VARCHAR(50) UNIQUE NOT NULL,
    name                VARCHAR(150) NOT NULL,
    email               VARCHAR(150),
    phone               VARCHAR(30),
    role_title          VARCHAR(100),
    organization        VARCHAR(150),
    emergency_contact   VARCHAR(150),
    expedition_id       UUID REFERENCES expeditions(id),
    current_location_id UUID REFERENCES locations(id),
    status              VARCHAR(20) NOT NULL DEFAULT 'ACTIVE',
    linked_user_id      UUID REFERENCES users(id),
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_personnel_expedition ON personnel(expedition_id);
CREATE INDEX idx_personnel_status ON personnel(status);

CREATE TABLE personnel_movements (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    personnel_id        UUID NOT NULL REFERENCES personnel(id) ON DELETE CASCADE,
    from_location_id    UUID REFERENCES locations(id),
    to_location_id      UUID REFERENCES locations(id),
    start_time          TIMESTAMPTZ NOT NULL,
    expected_arrival    TIMESTAMPTZ,
    actual_arrival      TIMESTAMPTZ,
    transport_mode      VARCHAR(30),
    status              VARCHAR(20) NOT NULL DEFAULT 'PLANNED',
    created_by          UUID REFERENCES users(id),
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_movements_personnel ON personnel_movements(personnel_id);
CREATE INDEX idx_movements_status ON personnel_movements(status);

-- =========================================================
-- 5. CARGO
-- =========================================================

CREATE TABLE cargo (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    cargo_code          VARCHAR(50) UNIQUE NOT NULL,
    name                VARCHAR(200) NOT NULL,
    category            VARCHAR(40) NOT NULL,
    description         TEXT,
    quantity            NUMERIC(12,2) NOT NULL DEFAULT 1,
    weight_kg           NUMERIC(12,2),
    priority            VARCHAR(20) NOT NULL DEFAULT 'MEDIUM',
    origin_id           UUID REFERENCES locations(id),
    destination_id      UUID REFERENCES locations(id),
    current_location_id UUID REFERENCES locations(id),
    expedition_id       UUID REFERENCES expeditions(id),
    transport_mode      VARCHAR(30),
    expected_arrival    TIMESTAMPTZ,
    actual_arrival      TIMESTAMPTZ,
    status              VARCHAR(20) NOT NULL DEFAULT 'REGISTERED',
    qr_code_value       VARCHAR(255) UNIQUE,
    version             INTEGER NOT NULL DEFAULT 0,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_cargo_status ON cargo(status);
CREATE INDEX idx_cargo_expedition ON cargo(expedition_id);
CREATE INDEX idx_cargo_priority ON cargo(priority);

CREATE TABLE cargo_movements (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    cargo_id            UUID NOT NULL REFERENCES cargo(id) ON DELETE CASCADE,
    previous_location_id UUID REFERENCES locations(id),
    new_location_id     UUID REFERENCES locations(id),
    previous_status     VARCHAR(20),
    new_status          VARCHAR(20),
    reason              VARCHAR(255),
    updated_by          UUID REFERENCES users(id),
    created_offline     BOOLEAN NOT NULL DEFAULT FALSE,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_cargo_movements_cargo ON cargo_movements(cargo_id);

-- =========================================================
-- 6. INVENTORY
-- =========================================================

CREATE TABLE inventory_items (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    item_code           VARCHAR(50) UNIQUE NOT NULL,
    item_name           VARCHAR(150) NOT NULL,
    category            VARCHAR(40) NOT NULL,
    unit                VARCHAR(20) NOT NULL,
    current_quantity    NUMERIC(14,2) NOT NULL DEFAULT 0,
    minimum_quantity    NUMERIC(14,2) NOT NULL DEFAULT 0,
    maximum_quantity    NUMERIC(14,2),
    storage_location_id UUID REFERENCES locations(id),
    expedition_id       UUID REFERENCES expeditions(id),
    avg_daily_consumption NUMERIC(14,4) DEFAULT 0,
    version             INTEGER NOT NULL DEFAULT 0,
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_inventory_expedition ON inventory_items(expedition_id);
CREATE INDEX idx_inventory_category ON inventory_items(category);

CREATE TABLE inventory_transactions (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    inventory_item_id   UUID NOT NULL REFERENCES inventory_items(id) ON DELETE CASCADE,
    transaction_type    VARCHAR(20) NOT NULL,
    quantity            NUMERIC(14,2) NOT NULL,
    balance_after       NUMERIC(14,2) NOT NULL,
    reason              VARCHAR(255),
    performed_by        UUID REFERENCES users(id),
    created_offline     BOOLEAN NOT NULL DEFAULT FALSE,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_inv_txn_item ON inventory_transactions(inventory_item_id);

-- =========================================================
-- 7. ASSETS
-- =========================================================

CREATE TABLE assets (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    asset_code          VARCHAR(50) UNIQUE NOT NULL,
    asset_name          VARCHAR(150) NOT NULL,
    asset_type          VARCHAR(40) NOT NULL,
    serial_number       VARCHAR(100),
    location_id         UUID REFERENCES locations(id),
    expedition_id       UUID REFERENCES expeditions(id),
    assigned_personnel_id UUID REFERENCES personnel(id),
    condition           VARCHAR(30) NOT NULL DEFAULT 'OPERATIONAL',
    purchase_date        DATE,
    last_maintenance_date DATE,
    next_maintenance_date DATE,
    maintenance_interval_hours NUMERIC(10,2),
    operating_hours      NUMERIC(12,2) NOT NULL DEFAULT 0,
    qr_code_value        VARCHAR(255) UNIQUE,
    version              INTEGER NOT NULL DEFAULT 0,
    created_at           TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at           TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_assets_condition ON assets(condition);
CREATE INDEX idx_assets_expedition ON assets(expedition_id);

CREATE TABLE asset_assignments (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    asset_id            UUID NOT NULL REFERENCES assets(id) ON DELETE CASCADE,
    expedition_id       UUID REFERENCES expeditions(id),
    personnel_id        UUID REFERENCES personnel(id),
    assigned_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    released_at         TIMESTAMPTZ,
    notes               VARCHAR(255)
);
CREATE INDEX idx_asset_assign_asset ON asset_assignments(asset_id);

CREATE TABLE maintenance_records (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    asset_id            UUID NOT NULL REFERENCES assets(id) ON DELETE CASCADE,
    maintenance_type    VARCHAR(50) NOT NULL,
    performed_date       DATE,
    technician           VARCHAR(150),
    description           TEXT,
    cost                  NUMERIC(12,2),
    next_maintenance_date DATE,
    status                VARCHAR(20) NOT NULL DEFAULT 'SCHEDULED',
    created_at            TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_maintenance_asset ON maintenance_records(asset_id);
CREATE INDEX idx_maintenance_status ON maintenance_records(status);

-- =========================================================
-- 8. EMERGENCIES
-- =========================================================

CREATE TABLE emergencies (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    emergency_code      VARCHAR(50) UNIQUE NOT NULL,
    type                VARCHAR(40) NOT NULL,
    priority            VARCHAR(20) NOT NULL DEFAULT 'MEDIUM',
    location_id         UUID REFERENCES locations(id),
    latitude            DOUBLE PRECISION,
    longitude           DOUBLE PRECISION,
    reported_by         UUID REFERENCES users(id),
    expedition_id       UUID REFERENCES expeditions(id),
    reported_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    description         TEXT,
    people_affected     INTEGER DEFAULT 0,
    status              VARCHAR(20) NOT NULL DEFAULT 'REPORTED',
    assigned_leader_id  UUID REFERENCES users(id),
    resolved_at         TIMESTAMPTZ,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_emergencies_status ON emergencies(status);
CREATE INDEX idx_emergencies_priority ON emergencies(priority);

CREATE TABLE emergency_resources (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    emergency_id        UUID NOT NULL REFERENCES emergencies(id) ON DELETE CASCADE,
    resource_type       VARCHAR(30) NOT NULL,
    personnel_id        UUID REFERENCES personnel(id),
    asset_id            UUID REFERENCES assets(id),
    inventory_item_id   UUID REFERENCES inventory_items(id),
    is_recommended       BOOLEAN NOT NULL DEFAULT TRUE,
    is_approved          BOOLEAN NOT NULL DEFAULT FALSE,
    approved_by          UUID REFERENCES users(id),
    notes                 VARCHAR(255),
    created_at            TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_emergency_resources_emergency ON emergency_resources(emergency_id);

-- =========================================================
-- 9. ALERTS & NOTIFICATIONS
-- =========================================================

CREATE TABLE alerts (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    alert_type          VARCHAR(50) NOT NULL,
    severity            VARCHAR(20) NOT NULL DEFAULT 'WARNING',
    message             TEXT NOT NULL,
    related_entity_type VARCHAR(40),
    related_entity_id   UUID,
    expedition_id       UUID REFERENCES expeditions(id),
    status              VARCHAR(20) NOT NULL DEFAULT 'NEW',
    acknowledged_by     UUID REFERENCES users(id),
    acknowledged_at     TIMESTAMPTZ,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_alerts_status ON alerts(status);
CREATE INDEX idx_alerts_severity ON alerts(severity);
CREATE INDEX idx_alerts_entity ON alerts(related_entity_type, related_entity_id);

CREATE TABLE notifications (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id             UUID REFERENCES users(id) ON DELETE CASCADE,
    title               VARCHAR(200) NOT NULL,
    message             TEXT,
    related_alert_id    UUID REFERENCES alerts(id),
    is_read             BOOLEAN NOT NULL DEFAULT FALSE,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_notifications_user ON notifications(user_id, is_read);

-- =========================================================
-- 10. AUDIT LOG
-- =========================================================

CREATE TABLE audit_logs (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id             UUID REFERENCES users(id),
    action              VARCHAR(100) NOT NULL,
    entity_type         VARCHAR(50) NOT NULL,
    entity_id           UUID,
    old_value           JSONB,
    new_value           JSONB,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX idx_audit_entity ON audit_logs(entity_type, entity_id);
CREATE INDEX idx_audit_user ON audit_logs(user_id);

-- =========================================================
-- 11. OFFLINE SYNC QUEUE
-- =========================================================

CREATE TABLE sync_queue (
    id                  UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    client_id           UUID NOT NULL,
    user_id             UUID REFERENCES users(id),
    entity_type         VARCHAR(50) NOT NULL,
    entity_id           UUID,
    operation           VARCHAR(20) NOT NULL,
    payload             JSONB NOT NULL,
    client_timestamp    TIMESTAMPTZ NOT NULL,
    server_timestamp    TIMESTAMPTZ,
    status              VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    conflict_reason     VARCHAR(255),
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX idx_sync_client_id ON sync_queue(client_id);
CREATE INDEX idx_sync_status ON sync_queue(status);

-- =========================================================
-- Seed roles (fixed reference data)
-- =========================================================
INSERT INTO roles (name, description) VALUES
 ('ADMIN', 'Full system access'),
 ('LOGISTICS_OFFICER', 'Manages cargo, inventory, transportation'),
 ('EXPEDITION_LEADER', 'Manages expedition, personnel, field operations'),
 ('FIELD_STAFF', 'Field operations, tasks, SOS');
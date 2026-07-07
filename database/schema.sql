-- ============================================================
-- Momo Paradise - Database Schema
-- PostgreSQL (deploy on Render)
-- Tables are created in dependency order so foreign keys resolve.
-- ============================================================

-- ---------- BRANCH ----------
CREATE TABLE branch (
    branch_id   SERIAL PRIMARY KEY,
    name        VARCHAR(100) NOT NULL,
    address     VARCHAR(255) NOT NULL,
    phone       VARCHAR(20)
);

-- ---------- CUSTOMER ----------
CREATE TABLE customer (
    customer_id   SERIAL PRIMARY KEY,
    name          VARCHAR(100) NOT NULL,
    email         VARCHAR(150) NOT NULL UNIQUE,
    phone         VARCHAR(20),
    password_hash VARCHAR(255) NOT NULL          -- never store plaintext passwords
);

-- ---------- STAFF ----------
CREATE TABLE staff (
    staff_id      SERIAL PRIMARY KEY,
    branch_id     INT NOT NULL REFERENCES branch(branch_id),
    name          VARCHAR(100) NOT NULL,
    role          VARCHAR(50) NOT NULL,
    password_hash VARCHAR(255) NOT NULL
);

-- ---------- MEMBERSHIP (1-to-1 with customer) ----------
CREATE TABLE membership (
    membership_id SERIAL PRIMARY KEY,
    customer_id   INT NOT NULL UNIQUE REFERENCES customer(customer_id),  -- UNIQUE enforces 1-to-1
    points        INT NOT NULL DEFAULT 0,
    tier          VARCHAR(50) NOT NULL DEFAULT 'standard'
);

-- ---------- DINING_TABLE ----------
CREATE TABLE dining_table (
    table_id   SERIAL PRIMARY KEY,
    branch_id  INT NOT NULL REFERENCES branch(branch_id),
    capacity   INT NOT NULL CHECK (capacity > 0),
    status     VARCHAR(20) NOT NULL DEFAULT 'available'
);

-- ---------- BUFFET_TIER ----------
CREATE TABLE buffet_tier (
    tier_id          SERIAL PRIMARY KEY,
    branch_id        INT NOT NULL REFERENCES branch(branch_id),
    name             VARCHAR(100) NOT NULL,
    price_per_head   DECIMAL(10,2) NOT NULL CHECK (price_per_head > 0),
    duration_minutes INT NOT NULL CHECK (duration_minutes > 0)
);

-- ---------- MENU_ITEM ----------
CREATE TABLE menu_item (
    item_id    SERIAL PRIMARY KEY,
    branch_id  INT NOT NULL REFERENCES branch(branch_id),
    name       VARCHAR(100) NOT NULL,
    category   VARCHAR(50),
    price      DECIMAL(10,2) NOT NULL DEFAULT 0 CHECK (price >= 0),  -- 0 = buffet-included
    available  BOOLEAN NOT NULL DEFAULT TRUE
);

-- ---------- TIER_MENU_ITEM (many-to-many: which items each tier can order) ----------
CREATE TABLE tier_menu_item (
    tier_id  INT NOT NULL REFERENCES buffet_tier(tier_id),
    item_id  INT NOT NULL REFERENCES menu_item(item_id),
    PRIMARY KEY (tier_id, item_id)             -- composite key
);

-- ---------- RESERVATION ----------
CREATE TABLE reservation (
    reservation_id SERIAL PRIMARY KEY,
    customer_id    INT NOT NULL REFERENCES customer(customer_id),
    branch_id      INT NOT NULL REFERENCES branch(branch_id),
    table_id       INT REFERENCES dining_table(table_id),   -- nullable: queued walk-ins have no table yet
    slot_time      TIMESTAMP,                               -- nullable: queued entries have no set time
    party_size     INT NOT NULL CHECK (party_size > 0),
    status         VARCHAR(20) NOT NULL DEFAULT 'reserved'
                   CHECK (status IN ('reserved','queued','seated','cancelled','no_show'))
);

-- ---------- DINING_SESSION ----------
CREATE TABLE dining_session (
    session_id     SERIAL PRIMARY KEY,
    reservation_id INT REFERENCES reservation(reservation_id),  -- nullable: pure walk-ins
    branch_id      INT NOT NULL REFERENCES branch(branch_id),
    table_id       INT NOT NULL REFERENCES dining_table(table_id),
    customer_id    INT NOT NULL REFERENCES customer(customer_id),
    tier_id        INT NOT NULL REFERENCES buffet_tier(tier_id),
    staff_id       INT NOT NULL REFERENCES staff(staff_id),
    start_time     TIMESTAMP NOT NULL DEFAULT NOW(),
    end_time       TIMESTAMP,
    guest_count    INT NOT NULL CHECK (guest_count > 0),
    status         VARCHAR(20) NOT NULL DEFAULT 'active'
);

-- ---------- ORDER_LINE ----------
CREATE TABLE order_line (
    order_line_id SERIAL PRIMARY KEY,
    session_id    INT NOT NULL REFERENCES dining_session(session_id),
    item_id       INT NOT NULL REFERENCES menu_item(item_id),
    quantity      INT NOT NULL CHECK (quantity > 0),
    unit_price    DECIMAL(10,2) NOT NULL,   -- copied from menu_item.price at order time
    ordered_at    TIMESTAMP NOT NULL DEFAULT NOW(),
    status        VARCHAR(20) NOT NULL DEFAULT 'ordered'
);

-- ---------- PROMOTION ----------
CREATE TABLE promotion (
    promotion_id  SERIAL PRIMARY KEY,
    staff_id      INT NOT NULL REFERENCES staff(staff_id),
    code          VARCHAR(50) NOT NULL UNIQUE,
    discount      DECIMAL(10,2) NOT NULL CHECK (discount >= 0),
    discount_type VARCHAR(10) NOT NULL CHECK (discount_type IN ('percent','fixed')),
    valid_until   DATE
);

-- ---------- BILL ----------
CREATE TABLE bill (
    bill_id         SERIAL PRIMARY KEY,
    session_id      INT NOT NULL UNIQUE REFERENCES dining_session(session_id),  -- one bill per session
    promotion_id    INT REFERENCES promotion(promotion_id),   -- nullable: most bills have no coupon
    buffet_total    DECIMAL(10,2) NOT NULL,
    extra_charges   DECIMAL(10,2) NOT NULL DEFAULT 0,
    discount_amount DECIMAL(10,2) NOT NULL DEFAULT 0,
    final_total     DECIMAL(10,2) NOT NULL,
    payment_method  VARCHAR(30),
    payment_status  VARCHAR(20) NOT NULL DEFAULT 'unpaid',
    paid_at         TIMESTAMP
);

-- ---------- POINT_TRANSACTION ----------
CREATE TABLE point_transaction (
    transaction_id SERIAL PRIMARY KEY,
    membership_id  INT NOT NULL REFERENCES membership(membership_id),
    bill_id        INT REFERENCES bill(bill_id),   -- nullable: adjustments not tied to a visit
    change_amount  INT NOT NULL,                   -- + earn, - redeem
    type           VARCHAR(10) NOT NULL CHECK (type IN ('earn','redeem')),
    created_at     TIMESTAMP NOT NULL DEFAULT NOW()
);

-- ============================================================
-- Indexes for heavy / frequent queries
-- ============================================================
-- Availability lookups: reservations by branch + time
CREATE INDEX idx_reservation_branch_time ON reservation (branch_id, slot_time);
-- Kitchen view: order lines by session + status
CREATE INDEX idx_order_line_session_status ON order_line (session_id, status);
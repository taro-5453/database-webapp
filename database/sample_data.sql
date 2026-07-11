-- ============================================================
-- Momo Paradise - Sample Data
-- Run AFTER schema.sql. Inserts are in dependency order
-- (parent tables before child tables) so foreign keys resolve.
-- Passwords shown here are placeholder hashes for demo only.
-- ============================================================

-- ---------- BRANCH (10) ----------
INSERT INTO branch (name, address, phone) VALUES
('Momo Paradise Siam Paragon',   '991 Rama I Rd, Pathum Wan, Bangkok',        '02-111-1001'),
('Momo Paradise CentralWorld',   '999/9 Rama I Rd, Pathum Wan, Bangkok',      '02-111-1002'),
('Momo Paradise EmQuartier',     '693 Sukhumvit Rd, Watthana, Bangkok',       '02-111-1003'),
('Momo Paradise Terminal 21',    '88 Sukhumvit Rd, Watthana, Bangkok',        '02-111-1004'),
('Momo Paradise MBK Center',     '444 Phaya Thai Rd, Pathum Wan, Bangkok',    '02-111-1005'),
('Momo Paradise Future Rangsit', '94 Phahonyothin Rd, Pathum Thani',          '02-111-1006'),
('Momo Paradise Central Ladprao','1697 Phahonyothin Rd, Chatuchak, Bangkok',  '02-111-1007'),
('Momo Paradise Mega Bangna',    '39 Bang Na-Trat Rd, Samut Prakan',          '02-111-1008'),
('Momo Paradise Icon Siam',      '299 Charoen Nakhon Rd, Khlong San, Bangkok','02-111-1009'),
('Momo Paradise Central Rama 9', '9/9 Rama IX Rd, Huai Khwang, Bangkok',      '02-111-1010');

-- ---------- STAFF (12) ----------
INSERT INTO staff (branch_id, name, role, password_hash) VALUES
(1, 'Somchai Jaidee',      'manager', 'hash_s1'),
(1, 'Malee Rungroj',       'server',  'hash_s2'),
(2, 'Anan Wattana',        'manager', 'hash_s3'),
(2, 'Ploy Suksan',         'server',  'hash_s4'),
(3, 'Kittipong Meesap',    'manager', 'hash_s5'),
(3, 'Nid Chaicharoen',     'cashier', 'hash_s6'),
(4, 'Wich Thongdee',       'manager', 'hash_s7'),
(5, 'Suda Panya',          'server',  'hash_s8'),
(6, 'Chai Boonmee',        'manager', 'hash_s9'),
(7, 'Fah Siriwan',         'cashier', 'hash_s10'),
(8, 'Note Prasert',        'manager', 'hash_s11'),
(9, 'Aom Rattana',         'server',  'hash_s12');

-- ---------- CUSTOMER (12) ----------
INSERT INTO customer (name, email, phone, password_hash) VALUES
('Nattapong Sri',    'nattapong@example.com', '081-000-0001', 'hash_c1'),
('Suchada Wong',     'suchada@example.com',   '081-000-0002', 'hash_c2'),
('Peerapat Kul',     'peerapat@example.com',  '081-000-0003', 'hash_c3'),
('Waraporn Chan',    'waraporn@example.com',  '081-000-0004', 'hash_c4'),
('Thanakorn Lim',    'thanakorn@example.com', '081-000-0005', 'hash_c5'),
('Kanya Somboon',    'kanya@example.com',     '081-000-0006', 'hash_c6'),
('Direk Phong',      'direk@example.com',     '081-000-0007', 'hash_c7'),
(' Intira Nakhon',   'intira@example.com',    '081-000-0008', 'hash_c8'),
('Sarawut Deng',     'sarawut@example.com',   '081-000-0009', 'hash_c9'),
('Benjawan Rak',     'benjawan@example.com',  '081-000-0010', 'hash_c10'),
('Chalermchai Ton',  'chalermchai@example.com','081-000-0011','hash_c11'),
('Pimchanok Ura',    'pimchanok@example.com', '081-000-0012', 'hash_c12');

-- ---------- MEMBERSHIP (10, one per customer) ----------
INSERT INTO membership (customer_id, points, tier) VALUES
(1, 120, 'silver'),
(2, 340, 'gold'),
(3, 50,  'standard'),
(4, 780, 'gold'),
(5, 15,  'standard'),
(6, 220, 'silver'),
(7, 90,  'standard'),
(8, 410, 'gold'),
(9, 30,  'standard'),
(10,160, 'silver');

-- ---------- DINING_TABLE (12) ----------
INSERT INTO dining_table (branch_id, capacity, status) VALUES
(1, 2, 'available'),
(1, 4, 'available'),
(1, 4, 'occupied'),
(1, 6, 'available'),
(2, 2, 'available'),
(2, 4, 'occupied'),
(2, 6, 'available'),
(3, 4, 'available'),
(3, 8, 'available'),
(4, 4, 'occupied'),
(5, 2, 'available'),
(6, 6, 'available');

-- ---------- BUFFET_TIER (10) ----------
INSERT INTO buffet_tier (branch_id, name, price_per_head, duration_minutes) VALUES
(1, 'Standard',  399.00, 90),
(1, 'Premium',   599.00, 120),
(2, 'Standard',  399.00, 90),
(2, 'Premium',   599.00, 120),
(3, 'Standard',  399.00, 90),
(3, 'Deluxe',    799.00, 120),
(4, 'Standard',  399.00, 90),
(5, 'Standard',  399.00, 90),
(6, 'Premium',   599.00, 120),
(7, 'Standard',  399.00, 90);

-- ---------- MENU_ITEM (14) ----------
-- price = 0 for buffet-included items; > 0 for extra-charge items
INSERT INTO menu_item (branch_id, name, category, price, available) VALUES
(1, 'Pork Slices',         'meat',      0.00, TRUE),
(1, 'Beef Slices',         'meat',      0.00, TRUE),
(1, 'Premium Wagyu',       'meat',      0.00, TRUE),
(1, 'Shrimp',              'seafood',   0.00, TRUE),
(1, 'Salmon Slices',       'seafood',   0.00, TRUE),
(1, 'Enoki Mushroom',      'vegetable', 0.00, TRUE),
(1, 'Napa Cabbage',        'vegetable', 0.00, TRUE),
(1, 'Udon Noodles',        'noodle',    0.00, TRUE),
(1, 'Tofu',                'vegetable', 0.00, TRUE),
(1, 'Fish Ball',           'meat',      0.00, TRUE),
(1, 'Coca-Cola',           'drink',    39.00, TRUE),
(1, 'Fresh Orange Juice',  'drink',    59.00, TRUE),
(1, 'Green Tea Ice Cream', 'dessert',  49.00, TRUE),
(1, 'Premium Sake',        'drink',   199.00, TRUE);

-- ---------- TIER_MENU_ITEM (which items each tier can order) ----------
-- Standard tier (tier 1): basic items only
INSERT INTO tier_menu_item (tier_id, item_id) VALUES
(1, 1),(1, 2),(1, 4),(1, 6),(1, 7),(1, 8),(1, 9),(1, 10),(1, 11),(1, 12),(1, 13);
-- Premium tier (tier 2): everything including wagyu, salmon, sake
INSERT INTO tier_menu_item (tier_id, item_id) VALUES
(2, 1),(2, 2),(2, 3),(2, 4),(2, 5),(2, 6),(2, 7),(2, 8),(2, 9),(2, 10),(2, 11),(2, 12),(2, 13),(2, 14);

-- ---------- PROMOTION (10) ----------
INSERT INTO promotion (staff_id, code, discount, discount_type, valid_until) VALUES
(1, 'WELCOME10',  10.00, 'percent', '2026-12-31'),
(1, 'MEMBER50',   50.00, 'fixed',   '2026-12-31'),
(3, 'BDAY15',     15.00, 'percent', '2026-12-31'),
(3, 'LUNCH20',    20.00, 'percent', '2026-09-30'),
(5, 'FAMILY100', 100.00, 'fixed',   '2026-12-31'),
(5, 'STUDENT10',  10.00, 'percent', '2026-12-31'),
(7, 'WEEKDAY25',  25.00, 'percent', '2026-10-31'),
(9, 'GRAND200',  200.00, 'fixed',   '2026-08-31'),
(11,'FIRST5',      5.00, 'percent', '2026-12-31'),
(2, 'SONGKRAN30', 30.00, 'percent', '2026-04-30');

-- ---------- RESERVATION (12) : mix of reserved, queued, seated, cancelled, no_show ----------
-- Tables are no longer stored here: staff assign them at seating
-- time through reservation_table (a party can combine several).
INSERT INTO reservation (customer_id, branch_id, slot_time, party_size, status) VALUES
(1, 1, '2026-07-10 18:00:00', 4, 'reserved'),
(2, 1, '2026-07-10 19:00:00', 6, 'reserved'),
(3, 2, NULL,                  2, 'queued'),
(4, 2, '2026-07-10 18:30:00', 6, 'seated'),
(5, 3, '2026-07-11 12:00:00', 4, 'reserved'),
(6, 3, NULL,                  3, 'queued'),
(7, 4, '2026-07-09 20:00:00', 4, 'no_show'),
(8, 1, '2026-07-08 18:00:00', 4, 'seated'),
(9, 2, '2026-07-08 19:30:00', 4, 'seated'),
(10,5, '2026-07-12 17:00:00', 2, 'reserved'),
(11,1, NULL,                  2, 'cancelled'),
(12,6, '2026-07-13 18:00:00', 6, 'reserved');

-- ---------- RESERVATION_TABLE : tables assigned to the seated parties ----------
-- Only the 'seated' reservations above have tables yet; matches the
-- dining_session rows below (reservation 4 -> table 7, 8 -> 3, 9 -> 6).
INSERT INTO reservation_table (reservation_id, table_id) VALUES
(4, 7),
(8, 3),
(9, 6);

-- ---------- DINING_SESSION (10) ----------
-- Some linked to a reservation, some pure walk-ins (reservation_id NULL)
INSERT INTO dining_session
  (reservation_id, branch_id, table_id, customer_id, tier_id, staff_id, start_time, end_time, guest_count, status) VALUES
(4,    2, 7, 4, 3, 4, '2026-07-10 18:30:00', NULL,                  6, 'active'),
(8,    1, 3, 8, 2, 2, '2026-07-08 18:05:00', '2026-07-08 20:00:00', 4, 'closed'),
(9,    2, 6, 9, 3, 4, '2026-07-08 19:35:00', '2026-07-08 21:20:00', 4, 'closed'),
(NULL, 1, 3, 1, 1, 2, '2026-07-08 12:10:00', '2026-07-08 13:40:00', 3, 'closed'),
(NULL, 3, 8, 5, 5, 5, '2026-07-08 13:00:00', '2026-07-08 14:45:00', 4, 'closed'),
(NULL, 1, 2, 6, 2, 1, '2026-07-08 19:00:00', '2026-07-08 20:55:00', 2, 'closed'),
(NULL, 2, 5, 7, 3, 4, '2026-07-08 12:30:00', '2026-07-08 14:00:00', 2, 'closed'),
(NULL, 4, 10,10, 7, 7, '2026-07-08 18:15:00', '2026-07-08 20:10:00', 4, 'closed'),
(NULL, 1, 4, 2, 1, 2, '2026-07-08 20:00:00', '2026-07-08 21:30:00', 5, 'closed'),
(NULL, 5, 11,3, 8, 8, '2026-07-08 17:20:00', '2026-07-08 18:50:00', 2, 'closed');

-- ---------- ORDER_LINE (14) : dishes ordered during sessions ----------
-- unit_price copied from menu_item.price at order time (0 for buffet items)
INSERT INTO order_line (session_id, item_id, quantity, unit_price, ordered_at, status) VALUES
(1, 1, 3, 0.00,  '2026-07-10 18:40:00', 'served'),
(1, 4, 2, 0.00,  '2026-07-10 18:42:00', 'served'),
(1, 11,2, 39.00, '2026-07-10 18:45:00', 'served'),
(2, 2, 4, 0.00,  '2026-07-08 18:20:00', 'served'),
(2, 3, 2, 0.00,  '2026-07-08 18:25:00', 'served'),
(2, 14,1, 199.00,'2026-07-08 18:30:00', 'served'),
(3, 1, 3, 0.00,  '2026-07-08 19:50:00', 'served'),
(3, 12,3, 59.00, '2026-07-08 19:55:00', 'served'),
(4, 6, 2, 0.00,  '2026-07-08 12:20:00', 'served'),
(4, 8, 1, 0.00,  '2026-07-08 12:25:00', 'served'),
(5, 5, 2, 0.00,  '2026-07-08 13:10:00', 'served'),
(5, 13,4, 49.00, '2026-07-08 13:30:00', 'served'),
(6, 2, 2, 0.00,  '2026-07-08 19:15:00', 'served'),
(6, 11,1, 39.00, '2026-07-08 19:20:00', 'served');

-- ---------- BILL (9) : one per closed session ----------
-- buffet_total = tier price_per_head * guest_count; extra_charges = sum of paid order lines
INSERT INTO bill
  (session_id, promotion_id, buffet_total, extra_charges, discount_amount, final_total, payment_method, payment_status, paid_at) VALUES
(2, 1,  2396.00, 199.00, 259.50, 2335.50, 'credit_card', 'paid', '2026-07-08 20:05:00'),
(3, NULL, 1596.00, 177.00,   0.00, 1773.00, 'cash',        'paid', '2026-07-08 21:25:00'),
(4, NULL, 1197.00,   0.00,   0.00, 1197.00, 'qr',          'paid', '2026-07-08 13:45:00'),
(5, 2,  1596.00, 196.00,  50.00, 1742.00, 'credit_card', 'paid', '2026-07-08 14:50:00'),
(6, NULL, 1198.00,  39.00,   0.00, 1237.00, 'qr',          'paid', '2026-07-08 21:00:00'),
(7, NULL,  798.00,   0.00,   0.00,  798.00, 'cash',        'paid', '2026-07-08 14:05:00'),
(8, 7,  1596.00,   0.00, 399.00, 1197.00, 'credit_card', 'paid', '2026-07-08 20:15:00'),
(9, NULL,  1995.00,   0.00,   0.00, 1995.00, 'qr',          'paid', '2026-07-08 21:35:00'),
(10,NULL,  798.00,   0.00,   0.00,  798.00, 'cash',        'paid', '2026-07-08 18:55:00');

-- ---------- POINT_TRANSACTION (11) : earn/redeem history ----------
INSERT INTO point_transaction (membership_id, bill_id, change_amount, type, created_at) VALUES
(8, 1,  23, 'earn',   '2026-07-08 20:05:00'),
(9, 2,  17, 'earn',   '2026-07-08 21:25:00'),
(1, 3,  11, 'earn',   '2026-07-08 13:45:00'),
(5, 4,  17, 'earn',   '2026-07-08 14:50:00'),
(6, 5,  12, 'earn',   '2026-07-08 21:00:00'),
(7, 6,   7, 'earn',   '2026-07-08 14:05:00'),
(10,7,  11, 'earn',   '2026-07-08 20:15:00'),
(2, 8,  19, 'earn',   '2026-07-08 21:35:00'),
(3, 9,   7, 'earn',   '2026-07-08 18:55:00'),
(2, NULL,-50,'redeem', '2026-07-08 22:00:00'),
(4, NULL, 100,'earn',  '2026-07-01 10:00:00');




-- ============================================================
-- Momo Paradise - Sample Data ADDITION
-- Adds menu items for branches 2-7 and assigns tier menus for
-- tiers 3-10, so ordering works at every branch (not just branch 1).
-- Run AFTER schema.sql and sample_data.sql.
-- Branch 1 (tiers 1-2) already has items + tier menus, so it is
-- not repeated here.
-- ============================================================

-- ---------- MENU_ITEM for branches 2-7 ----------
-- Each branch gets the same core menu (basics priced 0 = buffet-included,
-- drinks/desserts priced > 0 = extra charge). Premium items included so
-- premium/deluxe tiers have something exclusive to unlock.

-- Branch 2
INSERT INTO menu_item (branch_id, name, category, price, available) VALUES
(2, 'Pork Slices',         'meat',      0.00, TRUE),  -- 15
(2, 'Beef Slices',         'meat',      0.00, TRUE),  -- 16
(2, 'Premium Wagyu',       'meat',      0.00, TRUE),  -- 17
(2, 'Shrimp',              'seafood',   0.00, TRUE),  -- 18
(2, 'Salmon Slices',       'seafood',   0.00, TRUE),  -- 19
(2, 'Enoki Mushroom',      'vegetable', 0.00, TRUE),  -- 20
(2, 'Udon Noodles',        'noodle',    0.00, TRUE),  -- 21
(2, 'Coca-Cola',           'drink',    39.00, TRUE),  -- 22
(2, 'Green Tea Ice Cream', 'dessert',  49.00, TRUE);  -- 23

-- Branch 3
INSERT INTO menu_item (branch_id, name, category, price, available) VALUES
(3, 'Pork Slices',         'meat',      0.00, TRUE),  -- 24
(3, 'Beef Slices',         'meat',      0.00, TRUE),  -- 25
(3, 'Premium Wagyu',       'meat',      0.00, TRUE),  -- 26
(3, 'Foie Gras',           'meat',      0.00, TRUE),  -- 27  (deluxe exclusive)
(3, 'Shrimp',              'seafood',   0.00, TRUE),  -- 28
(3, 'Salmon Slices',       'seafood',   0.00, TRUE),  -- 29
(3, 'Enoki Mushroom',      'vegetable', 0.00, TRUE),  -- 30
(3, 'Udon Noodles',        'noodle',    0.00, TRUE),  -- 31
(3, 'Coca-Cola',           'drink',    39.00, TRUE),  -- 32
(3, 'Premium Sake',        'drink',   199.00, TRUE);  -- 33

-- Branch 4
INSERT INTO menu_item (branch_id, name, category, price, available) VALUES
(4, 'Pork Slices',         'meat',      0.00, TRUE),  -- 34
(4, 'Beef Slices',         'meat',      0.00, TRUE),  -- 35
(4, 'Shrimp',              'seafood',   0.00, TRUE),  -- 36
(4, 'Enoki Mushroom',      'vegetable', 0.00, TRUE),  -- 37
(4, 'Udon Noodles',        'noodle',    0.00, TRUE),  -- 38
(4, 'Coca-Cola',           'drink',    39.00, TRUE);  -- 39

-- Branch 5
INSERT INTO menu_item (branch_id, name, category, price, available) VALUES
(5, 'Pork Slices',         'meat',      0.00, TRUE),  -- 40
(5, 'Beef Slices',         'meat',      0.00, TRUE),  -- 41
(5, 'Shrimp',              'seafood',   0.00, TRUE),  -- 42
(5, 'Enoki Mushroom',      'vegetable', 0.00, TRUE),  -- 43
(5, 'Udon Noodles',        'noodle',    0.00, TRUE),  -- 44
(5, 'Coca-Cola',           'drink',    39.00, TRUE);  -- 45

-- Branch 6
INSERT INTO menu_item (branch_id, name, category, price, available) VALUES
(6, 'Pork Slices',         'meat',      0.00, TRUE),  -- 46
(6, 'Beef Slices',         'meat',      0.00, TRUE),  -- 47
(6, 'Premium Wagyu',       'meat',      0.00, TRUE),  -- 48
(6, 'Salmon Slices',       'seafood',   0.00, TRUE),  -- 49
(6, 'Enoki Mushroom',      'vegetable', 0.00, TRUE),  -- 50
(6, 'Udon Noodles',        'noodle',    0.00, TRUE),  -- 51
(6, 'Premium Sake',        'drink',   199.00, TRUE);  -- 52

-- Branch 7
INSERT INTO menu_item (branch_id, name, category, price, available) VALUES
(7, 'Pork Slices',         'meat',      0.00, TRUE),  -- 53
(7, 'Beef Slices',         'meat',      0.00, TRUE),  -- 54
(7, 'Shrimp',              'seafood',   0.00, TRUE),  -- 55
(7, 'Enoki Mushroom',      'vegetable', 0.00, TRUE),  -- 56
(7, 'Udon Noodles',        'noodle',    0.00, TRUE),  -- 57
(7, 'Coca-Cola',           'drink',    39.00, TRUE);  -- 58


-- ---------- TIER_MENU_ITEM assignments ----------
-- Standard tiers: basic items (no wagyu/salmon/foie gras/sake).
-- Premium/Deluxe tiers: everything at that branch.

-- Branch 2: tier 3 = Standard, tier 4 = Premium
-- Standard (tier 3): pork, beef, shrimp, enoki, udon, coke, ice cream
INSERT INTO tier_menu_item (tier_id, item_id) VALUES
(3, 15),(3, 16),(3, 18),(3, 20),(3, 21),(3, 22),(3, 23);
-- Premium (tier 4): everything at branch 2 (adds wagyu 17, salmon 19)
INSERT INTO tier_menu_item (tier_id, item_id) VALUES
(4, 15),(4, 16),(4, 17),(4, 18),(4, 19),(4, 20),(4, 21),(4, 22),(4, 23);

-- Branch 3: tier 5 = Standard, tier 6 = Deluxe
-- Standard (tier 5): basics (no wagyu 26, foie gras 27, salmon 29, sake 33)
INSERT INTO tier_menu_item (tier_id, item_id) VALUES
(5, 24),(5, 25),(5, 28),(5, 30),(5, 31),(5, 32);
-- Deluxe (tier 6): everything at branch 3
INSERT INTO tier_menu_item (tier_id, item_id) VALUES
(6, 24),(6, 25),(6, 26),(6, 27),(6, 28),(6, 29),(6, 30),(6, 31),(6, 32),(6, 33);

-- Branch 4: tier 7 = Standard (only tier) -> all its items
INSERT INTO tier_menu_item (tier_id, item_id) VALUES
(7, 34),(7, 35),(7, 36),(7, 37),(7, 38),(7, 39);

-- Branch 5: tier 8 = Standard (only tier) -> all its items
INSERT INTO tier_menu_item (tier_id, item_id) VALUES
(8, 40),(8, 41),(8, 42),(8, 43),(8, 44),(8, 45);

-- Branch 6: tier 9 = Premium -> everything at branch 6 (incl wagyu 48, salmon 49, sake 52)
INSERT INTO tier_menu_item (tier_id, item_id) VALUES
(9, 46),(9, 47),(9, 48),(9, 49),(9, 50),(9, 51),(9, 52);

-- Branch 7: tier 10 = Standard (only tier) -> all its items
INSERT INTO tier_menu_item (tier_id, item_id) VALUES
(10, 53),(10, 54),(10, 55),(10, 56),(10, 57),(10, 58);
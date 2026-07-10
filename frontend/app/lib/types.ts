export type Branch = {
  branch_id: number;
  name: string;
  address: string;
  phone: string;
};

export type AvailableTable = {
  table_id: number;
  capacity: number;
  status: string;
};

export type Membership = {
  membership_id: number;
  customer_name: string;
  points: number;
  tier: string;
};

export type PointTransaction = {
  transaction_id: number;
  change_amount: number;
  type: string;
  bill_id: number | null;
  created_at: string;
};

export type Reservation = {
  reservation_id: number;
  status: string;
};

export type MenuItem = {
  item_id: number;
  name: string;
  category: string;
  price: number;
  available: boolean;
};

export type OrderLine = {
  order_line_id: number;
  item_name: string;
  quantity: number;
  unit_price: number;
  line_total: number;
  status: string;
  ordered_at: string;
};

export type Bill = {
  tier_id: number;
  price_per_head: number;
  guest_count: number;
  buffet_total: number;
  extra_charges: number;
  running_total: number;
};

export type QueueEntry = {
  queue_position: number;
  reservation_id: number;
  customer_id: number;
  customer_name: string;
  phone: string | null;
  party_size: number;
};

export type Tier = {
  tier_id: number;
  name: string;
  price_per_head: number;
  duration_minutes: number;
};

export type ActiveSession = {
  session_id: number;
  table_id: number;
  customer_name: string;
  guest_count: number;
  tier_name: string;
  duration_minutes: number;
  start_time: string;
  ends_at: string;
  minutes_remaining: number;
  staff_name: string;
};

export type KitchenOrderLine = {
  order_line_id: number;
  session_id: number;
  table_id: number;
  item_name: string;
  quantity: number;
  ordered_at: string;
  status: string;
};

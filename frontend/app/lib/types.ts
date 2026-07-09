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

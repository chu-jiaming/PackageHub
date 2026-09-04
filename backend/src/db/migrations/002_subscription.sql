CREATE TABLE subscriptions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  original_transaction_id text UNIQUE NOT NULL,
  product_id text NOT NULL,
  app_account_token uuid NOT NULL,
  environment text NOT NULL CHECK (environment IN ('Sandbox','Production')),
  status text NOT NULL CHECK (status IN ('active','trial','gracePeriod','billingRetry','expired','revoked')),
  latest_transaction_id text,
  expires_at timestamptz,
  auto_renew_enabled boolean,
  revoked_at timestamptz,
  last_reconciled_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX subscriptions_user_idx ON subscriptions(user_id);
CREATE TABLE app_store_notification_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  notification_uuid text UNIQUE NOT NULL,
  notification_type text NOT NULL,
  notification_subtype text,
  original_transaction_id text,
  received_at timestamptz NOT NULL DEFAULT now(),
  processed_at timestamptz
);
ALTER TABLE devices ADD COLUMN pro_access_granted_at timestamptz;
ALTER TABLE devices ADD COLUMN pro_access_revoked_at timestamptz;
CREATE TABLE subscription_binding_tombstones (
  original_transaction_id text PRIMARY KEY,
  deleted_at timestamptz NOT NULL DEFAULT now()
);
CREATE OR REPLACE FUNCTION preserve_subscription_bindings_before_user_delete() RETURNS trigger AS $$
BEGIN
  INSERT INTO subscription_binding_tombstones(original_transaction_id)
  SELECT original_transaction_id FROM subscriptions WHERE user_id=OLD.id
  ON CONFLICT DO NOTHING;
  RETURN OLD;
END;
$$ LANGUAGE plpgsql;
CREATE TRIGGER preserve_subscription_bindings BEFORE DELETE ON users
FOR EACH ROW EXECUTE FUNCTION preserve_subscription_bindings_before_user_delete();

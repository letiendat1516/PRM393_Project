-- =============================================================================
-- Migration 004 — Application status history table & update function
-- =============================================================================
-- Run this script in the Supabase SQL Editor.
-- =============================================================================

-- 1. Application status history table
CREATE TABLE IF NOT EXISTS application_status_history (
  id                BIGSERIAL PRIMARY KEY,
  application_id    BIGINT NOT NULL,
  old_status        VARCHAR(50),
  new_status        VARCHAR(50) NOT NULL,
  changed_by        BIGINT NOT NULL,
  changed_by_role   VARCHAR(50),
  changed_at        TIMESTAMPTZ DEFAULT now(),
  CONSTRAINT fk_ash_application
      FOREIGN KEY (application_id) REFERENCES application(application_id)
      ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_ash_application
  ON application_status_history (application_id);

-- 2. Trigger: auto-insert status history on application insert
CREATE OR REPLACE FUNCTION trg_application_status_history()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO application_status_history (
    application_id, old_status, new_status, changed_by, changed_by_role
  ) VALUES (
    NEW.application_id, NULL, NEW.status,
    NEW.job_seeker_id, 'job_seeker'
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS after_application_insert ON application;
CREATE TRIGGER after_application_insert
  AFTER INSERT ON application
  FOR EACH ROW
  EXECUTE FUNCTION trg_application_status_history();

-- 3. RPC: update application status atomically
CREATE OR REPLACE FUNCTION update_application_status(
  p_application_id   BIGINT,
  p_expected_status  VARCHAR,
  p_new_status       VARCHAR,
  p_changed_by       BIGINT,
  p_changed_by_role  VARCHAR DEFAULT NULL
)
RETURNS TABLE(
  application_id   BIGINT,
  old_status       VARCHAR,
  new_status       VARCHAR,
  updated_at       TIMESTAMPTZ
) AS $$
DECLARE
  v_old_status VARCHAR;
BEGIN
  -- Lock row and get current status
  SELECT status INTO v_old_status
  FROM application
  WHERE application_id = p_application_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'application not found' USING ERRCODE = '22023';
  END IF;

  IF v_old_status <> p_expected_status THEN
    RAISE EXCEPTION 'status conflict' USING ERRCODE = '40001';
  END IF;

  -- Update application status
  UPDATE application
  SET status = p_new_status, updated_at = now()
  WHERE application_id = p_application_id;

  -- Record history
  INSERT INTO application_status_history (
    application_id, old_status, new_status, changed_by, changed_by_role
  ) VALUES (
    p_application_id, v_old_status, p_new_status, p_changed_by, p_changed_by_role
  );

  RETURN QUERY
  SELECT a.application_id, v_old_status, a.status, a.updated_at
  FROM application a
  WHERE a.application_id = p_application_id;
END;
$$ LANGUAGE plpgsql;

-- =============================================================================
-- Migration 005 — Atomic Application Management status transition
-- =============================================================================
-- Review and apply through the Supabase SQL editor/deployment process.
-- This file is intentionally not applied automatically by the application.

BEGIN;

ALTER TABLE public.application_status_history
  ADD COLUMN IF NOT EXISTS changed_by_role VARCHAR(20);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_constraint
    WHERE conrelid = 'public.application_status_history'::regclass
      AND conname = 'chk_application_history_actor_role'
  ) THEN
    ALTER TABLE public.application_status_history
      ADD CONSTRAINT chk_application_history_actor_role
      CHECK (changed_by_role IS NULL OR changed_by_role IN ('job_seeker', 'employer', 'admin'));
  END IF;
END
$$;

-- Remove older overloads that did not verify job ownership inside the
-- transaction. Keeping them exposed would leave an unsafe alternate path.
DROP FUNCTION IF EXISTS public.update_application_status(
  BIGINT,
  public.application_status,
  public.application_status,
  BIGINT,
  VARCHAR
);

DROP FUNCTION IF EXISTS public.update_application_status(
  BIGINT,
  VARCHAR,
  VARCHAR,
  BIGINT,
  VARCHAR
);

CREATE OR REPLACE FUNCTION public.update_application_status(
  p_application_id BIGINT,
  p_expected_status public.application_status,
  p_new_status public.application_status,
  p_changed_by BIGINT,
  p_changed_by_role VARCHAR,
  p_employer_id BIGINT DEFAULT NULL,
  p_is_admin BOOLEAN DEFAULT FALSE
)
RETURNS TABLE (
  result_application_id BIGINT,
  result_status public.application_status,
  result_updated_at TIMESTAMPTZ,
  history_id BIGINT
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_current_status public.application_status;
  v_owning_employer_id BIGINT;
  v_saved_updated_at TIMESTAMPTZ;
  v_saved_history_id BIGINT;
BEGIN
  IF p_changed_by_role NOT IN ('employer', 'admin')
    OR (p_is_admin AND p_changed_by_role <> 'admin')
    OR (NOT p_is_admin AND p_changed_by_role <> 'employer') THEN
    RAISE EXCEPTION USING
      ERRCODE = '42501',
      MESSAGE = 'APPLICATION_FORBIDDEN';
  END IF;

  SELECT a.status, j.employer_id
  INTO v_current_status, v_owning_employer_id
  FROM public.application AS a
  JOIN public.job AS j ON j.job_id = a.job_id
  WHERE a.application_id = p_application_id
  FOR UPDATE OF a;

  IF NOT FOUND THEN
    RAISE EXCEPTION USING
      ERRCODE = 'P0002',
      MESSAGE = 'APPLICATION_NOT_FOUND';
  END IF;

  IF NOT p_is_admin AND v_owning_employer_id IS DISTINCT FROM p_employer_id THEN
    RAISE EXCEPTION USING
      ERRCODE = '42501',
      MESSAGE = 'APPLICATION_FORBIDDEN';
  END IF;

  IF v_current_status IS DISTINCT FROM p_expected_status THEN
    RAISE EXCEPTION USING
      ERRCODE = '40001',
      MESSAGE = 'APPLICATION_STATUS_CONFLICT';
  END IF;

  IF NOT (
    (v_current_status = 'SUBMITTED' AND p_new_status IN ('UNDER_REVIEW', 'ACCEPTED', 'REJECTED'))
    OR
    (v_current_status = 'UNDER_REVIEW' AND p_new_status IN ('ACCEPTED', 'REJECTED'))
  ) THEN
    RAISE EXCEPTION USING
      ERRCODE = '22023',
      MESSAGE = 'INVALID_STATUS_TRANSITION';
  END IF;

  UPDATE public.application
  SET status = p_new_status,
      updated_at = now()
  WHERE application_id = p_application_id
  RETURNING updated_at INTO v_saved_updated_at;

  INSERT INTO public.application_status_history (
    application_id,
    old_status,
    new_status,
    changed_by,
    changed_by_role,
    changed_at
  ) VALUES (
    p_application_id,
    v_current_status,
    p_new_status,
    p_changed_by,
    p_changed_by_role,
    now()
  )
  RETURNING id INTO v_saved_history_id;

  RETURN QUERY
  SELECT p_application_id, p_new_status, v_saved_updated_at, v_saved_history_id;
END;
$$;

REVOKE ALL ON FUNCTION public.update_application_status(
  BIGINT,
  public.application_status,
  public.application_status,
  BIGINT,
  VARCHAR,
  BIGINT,
  BOOLEAN
) FROM PUBLIC;

GRANT EXECUTE ON FUNCTION public.update_application_status(
  BIGINT,
  public.application_status,
  public.application_status,
  BIGINT,
  VARCHAR,
  BIGINT,
  BOOLEAN
) TO service_role;

COMMIT;

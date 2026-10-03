-- =============================================================================
-- Migration 003 — Performance indexes + is_approved default fix
-- =============================================================================
-- Run this script in the Supabase SQL Editor after the initial schema and
-- migrations 001 & 002 have been applied.
-- =============================================================================

-- 1. Index on job.category_id (ON DELETE SET NULL FK — unindexed in original schema)
CREATE INDEX IF NOT EXISTS idx_job_category_id
  ON job (category_id);

-- 2. Composite index for application status filtering (employer dashboard)
CREATE INDEX IF NOT EXISTS idx_app_status
  ON application (job_id, status);

-- 3. Fix default: new jobs should require approval before going live.
--    The application code always sets is_approved explicitly, but the DB
--    default should reflect the intended policy (safe default = FALSE).
ALTER TABLE job
  ALTER COLUMN is_approved SET DEFAULT FALSE;

-- Verify
-- SELECT column_name, column_default FROM information_schema.columns
-- WHERE table_name = 'job' AND column_name = 'is_approved';


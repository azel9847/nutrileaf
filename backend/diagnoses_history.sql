-- =============================================================================
-- NutriLeaf HHC-VNDC  —  diagnoses_history schema
-- Run this in the Supabase SQL Editor (Project > SQL Editor > New Query)
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 1. Storage bucket (idempotent)
-- ---------------------------------------------------------------------------
INSERT INTO storage.buckets (id, name, public)
VALUES ('diagnosis-images', 'diagnosis-images', true)
ON CONFLICT (id) DO NOTHING;

-- ---------------------------------------------------------------------------
-- 2. Core table
-- ---------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.diagnoses_history (
  -- Primary key
  id                   UUID PRIMARY KEY DEFAULT gen_random_uuid(),

  -- Optional FK to auth.users (NULL when called server-side without a user session)
  user_id              UUID REFERENCES auth.users (id) ON DELETE SET NULL,

  -- Stage-1 result: which of the 5 vegetables was detected
  vegetable            TEXT NOT NULL
                         CHECK (vegetable IN ('ampalaya', 'kalabasa', 'okra', 'sitaw', 'talong')),
  vegetable_confidence NUMERIC(8, 6) NOT NULL
                         CHECK (vegetable_confidence BETWEEN 0 AND 1),

  -- Stage-2 result: which nutrient deficiency was diagnosed
  diagnosed_deficiency TEXT NOT NULL
                         CHECK (diagnosed_deficiency IN ('healthy', 'nitrogen', 'phosphorus', 'potassium')),
  deficiency_confidence NUMERIC(8, 6) NOT NULL
                         CHECK (deficiency_confidence BETWEEN 0 AND 1),

  -- Full probability vectors (JSON) for analytics / charts
  vegetable_probabilities  JSONB,
  deficiency_probabilities JSONB,

  -- Image storage references
  image_url            TEXT,
  storage_path         TEXT,

  -- Metadata
  created_at           TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Index for fast per-user history queries
CREATE INDEX IF NOT EXISTS idx_diagnoses_history_user_id
  ON public.diagnoses_history (user_id, created_at DESC);

-- ---------------------------------------------------------------------------
-- 3. Row-Level Security
-- ---------------------------------------------------------------------------
ALTER TABLE public.diagnoses_history ENABLE ROW LEVEL SECURITY;

-- Authenticated users can read their own diagnoses
CREATE POLICY "Users can read their own diagnoses"
  ON public.diagnoses_history
  FOR SELECT
  USING (auth.uid() = user_id);

-- Authenticated users can insert diagnoses associated with their user_id
CREATE POLICY "Users can insert their own diagnoses"
  ON public.diagnoses_history
  FOR INSERT
  WITH CHECK (auth.uid() = user_id OR user_id IS NULL);

-- The service-role key (used by the backend) bypasses RLS by default,
-- so no additional service-role policy is required.

-- ---------------------------------------------------------------------------
-- 4. Storage RLS — allow anyone to view public images
-- ---------------------------------------------------------------------------
CREATE POLICY "Public read access on diagnosis-images"
  ON storage.objects
  FOR SELECT
  USING (bucket_id = 'diagnosis-images');

CREATE POLICY "Service role can upload diagnosis images"
  ON storage.objects
  FOR INSERT
  WITH CHECK (bucket_id = 'diagnosis-images');

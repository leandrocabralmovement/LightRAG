-- ============================================================================
-- LightRAG PostgreSQL Initialization Script
-- Creates pgvector extension and initial schema
-- ============================================================================

-- Enable pgvector extension
CREATE EXTENSION IF NOT EXISTS vector;

-- Create pgvector-based tables for LightRAG
-- Note: LightRAG will create additional tables as needed

-- Function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Log initialization
SELECT 'LightRAG PostgreSQL initialization completed' as status;

-- Migrated from Oracle to PostgreSQL according to SQL check item 1: Use lowercase for identifiers (like table and column names) and data type (like varchar), use uppercase for SQL keywords (like SELECT, FROM, WHERE).
-- This script runs automatically when PostgreSQL container starts
-- It creates the photoalbum user and grants necessary privileges

-- Create photoalbum user with password (PostgreSQL equivalent)
-- Note: User creation is handled by POSTGRES_USER environment variable in Docker
-- This script focuses on database setup

-- Create any additional schemas if needed
-- CREATE SCHEMA IF NOT EXISTS photoalbum AUTHORIZATION photoalbum;

-- Grant privileges (PostgreSQL automatically grants privileges to database owner)
-- Additional privileges can be granted here if needed

-- Note: PostgreSQL doesn't require explicit tablespace grants like Oracle
-- The user created via environment variables has sufficient privileges for the application
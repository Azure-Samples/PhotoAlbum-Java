-- Verification script to check if photoalbum user exists
-- Migrated from Oracle to PostgreSQL according to completeness validation
-- PostgreSQL uses different system catalogs than Oracle

-- Check if user/role exists in PostgreSQL
SELECT rolname, rolsuper, rolcreaterole, rolcreatedb 
FROM pg_roles 
WHERE rolname = 'photoalbum';

-- Show granted privileges for photoalbum user
SELECT grantee, table_catalog, table_schema, privilege_type 
FROM information_schema.table_privileges 
WHERE grantee = 'photoalbum';

\q
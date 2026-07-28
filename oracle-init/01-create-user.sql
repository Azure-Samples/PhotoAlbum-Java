-- This script runs automatically when the Oracle container starts.
--
-- The application schema user is created by the container itself from the
-- APP_USER / APP_USER_PASSWORD environment variables (see docker-compose.yml
-- and .env). Credentials are intentionally NOT hard-coded here.
--
-- This script only grants the least set of schema-scoped privileges the
-- application (Hibernate with ddl-auto=create) needs to manage its own
-- objects. It deliberately does NOT grant DBA or any system-wide "ANY"
-- privileges.

ALTER SESSION SET "_ORACLE_SCRIPT"=true;

-- Least-privilege grants for the application schema user.
-- NOTE: keep this user name in sync with APP_USER in docker-compose.yml / .env.
GRANT CREATE SESSION TO photoalbum;
GRANT CREATE TABLE TO photoalbum;
GRANT CREATE SEQUENCE TO photoalbum;
GRANT CREATE VIEW TO photoalbum;
GRANT CREATE PROCEDURE TO photoalbum;
GRANT CREATE TRIGGER TO photoalbum;
GRANT CREATE TYPE TO photoalbum;
GRANT CREATE SYNONYM TO photoalbum;

-- Allow the user to store objects in its default tablespace.
ALTER USER photoalbum QUOTA UNLIMITED ON USERS;

-- Set default and temporary tablespace
ALTER USER photoalbum DEFAULT TABLESPACE USERS;
ALTER USER photoalbum TEMPORARY TABLESPACE TEMP;

-- Commit the changes
COMMIT;

EXIT;
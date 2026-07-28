#!/bin/bash
# Ensures the application schema user exists in Oracle.
#
# Credentials are read from environment variables (provided by the container
# from docker-compose.yml / .env) and are NOT hard-coded in this file.
#   ORACLE_PASSWORD    - SYS/SYSTEM administrator password
#   APP_USER           - application schema user name (default: photoalbum)
#   APP_USER_PASSWORD  - application schema user password
set -euo pipefail

: "${ORACLE_PASSWORD:?ORACLE_PASSWORD must be set}"
: "${APP_USER:=photoalbum}"
: "${APP_USER_PASSWORD:?APP_USER_PASSWORD must be set}"

# Wait for Oracle to be fully ready
echo "Waiting for Oracle to be ready..."
sleep 30

APP_USER_UPPER=$(printf '%s' "$APP_USER" | tr '[:lower:]' '[:upper:]')

# Connect to Oracle as SYSTEM and create the application user if missing.
sqlplus -s "system/${ORACLE_PASSWORD}@//localhost:1521/XE" <<EOF
SET SERVEROUTPUT ON
DECLARE
    user_exists NUMBER;
BEGIN
    SELECT COUNT(*) INTO user_exists FROM dba_users WHERE username = '${APP_USER_UPPER}';

    IF user_exists = 0 THEN
        EXECUTE IMMEDIATE 'CREATE USER "${APP_USER_UPPER}" IDENTIFIED BY "${APP_USER_PASSWORD}"';
        EXECUTE IMMEDIATE 'GRANT CREATE SESSION TO "${APP_USER_UPPER}"';
        EXECUTE IMMEDIATE 'GRANT CREATE TABLE TO "${APP_USER_UPPER}"';
        EXECUTE IMMEDIATE 'GRANT CREATE SEQUENCE TO "${APP_USER_UPPER}"';
        EXECUTE IMMEDIATE 'ALTER USER "${APP_USER_UPPER}" QUOTA UNLIMITED ON USERS';
        EXECUTE IMMEDIATE 'ALTER USER "${APP_USER_UPPER}" DEFAULT TABLESPACE USERS';

        DBMS_OUTPUT.PUT_LINE('Application user created successfully');
    ELSE
        DBMS_OUTPUT.PUT_LINE('Application user already exists');
    END IF;
END;
/

exit;
EOF

echo "User creation script completed."
#!/bin/bash
# Create the application database user (non-superuser) for RLS enforcement.
# This runs automatically on first `docker compose up` via
# PostgreSQL's /docker-entrypoint-initdb.d/ mechanism.
#
# The database itself (crm_db) is created by the POSTGRES_DB env var.
# The role's password comes from CRM_USER_PASSWORD at runtime so it never
# needs to be committed to the repository.
set -e

: "${CRM_USER_PASSWORD:?CRM_USER_PASSWORD must be set}"

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    DO \$\$
    BEGIN
        IF NOT EXISTS (SELECT FROM pg_catalog.pg_roles WHERE rolname = 'crm_user') THEN
            CREATE ROLE crm_user WITH LOGIN PASSWORD '$CRM_USER_PASSWORD';
        ELSE
            ALTER ROLE crm_user WITH LOGIN PASSWORD '$CRM_USER_PASSWORD';
        END IF;
    END
    \$\$;

    GRANT ALL PRIVILEGES ON DATABASE $POSTGRES_DB TO crm_user;
EOSQL

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    GRANT ALL ON SCHEMA public TO crm_user;
    ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO crm_user;
    ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO crm_user;
    ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON FUNCTIONS TO crm_user;
EOSQL

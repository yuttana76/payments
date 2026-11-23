-- Runs once, when the Postgres data volume is first created.
-- One database per service: each service owns its data.
CREATE DATABASE IF NOT EXISTS wallet;
CREATE DATABASE IF NOT EXISTS auth;
CREATE DATABASE IF NOT EXISTS transfer;
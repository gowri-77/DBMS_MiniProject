-- =====================================================================
-- 00_reset.sql  |  LOCAL DEVELOPMENT ONLY
-- Wipes everything in the public schema so all SQL files can be re-run
-- from scratch. Never run this against a shared or demo database.
-- =====================================================================
DROP SCHEMA public CASCADE;
CREATE SCHEMA public;

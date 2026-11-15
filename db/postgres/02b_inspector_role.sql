-- Aligns the users table with docs/contract.md: role INSPECTOR (was QUALITY_INSPECTOR).
-- Re-runnable. Drops every CHECK on users that mentions the old name, converts the rows,
-- then re-creates the constraints with the new name.
DO $$
DECLARE c record;
BEGIN
  CREATE TEMP TABLE old_checks ON COMMIT DROP AS
    SELECT conname, pg_get_constraintdef(oid) AS def
    FROM pg_constraint
    WHERE conrelid = 'users'::regclass AND contype = 'c'
      AND pg_get_constraintdef(oid) LIKE '%QUALITY_INSPECTOR%';

  FOR c IN SELECT * FROM old_checks LOOP
    EXECUTE format('ALTER TABLE users DROP CONSTRAINT %I', c.conname);
  END LOOP;

  UPDATE users SET role = 'INSPECTOR' WHERE role = 'QUALITY_INSPECTOR';

  FOR c IN SELECT * FROM old_checks LOOP
    EXECUTE format('ALTER TABLE users ADD CONSTRAINT %I %s',
                   c.conname, replace(c.def, 'QUALITY_INSPECTOR', 'INSPECTOR'));
  END LOOP;
END $$;

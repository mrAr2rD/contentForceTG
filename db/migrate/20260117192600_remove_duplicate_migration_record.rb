class RemoveDuplicateMigrationRecord < ActiveRecord::Migration[8.1]
  def up
    # Remove the duplicate migration record from schema_migrations table
    # This migration (20260116201427) was a duplicate of 20260116201711
    execute("DELETE FROM schema_migrations WHERE version = '20260116201427'")
  end

  def down
    # No need to restore the duplicate record
  end
end

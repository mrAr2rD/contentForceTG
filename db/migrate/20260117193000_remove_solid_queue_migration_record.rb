class RemoveSolidQueueMigrationRecord < ActiveRecord::Migration[8.1]
  def up
    # Remove Solid Queue migration record from schema_migrations table
    # The tables are created via db:schema:load:queue in docker-entrypoint
    execute("DELETE FROM schema_migrations WHERE version = '20260116202900'")
  end

  def down
    # No need to restore the record
  end
end

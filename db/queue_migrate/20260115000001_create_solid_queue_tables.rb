# This migration marks the Solid Queue tables as already created.
# The actual tables are created from queue_schema.rb on initial setup.
# This prevents Rails from trying to run db:schema:load on production.
class CreateSolidQueueTables < ActiveRecord::Migration[8.1]
  def change
    # Tables already exist from queue_schema.rb
    # This migration just tracks that they're created
  end
end

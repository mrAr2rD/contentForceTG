# This migration marks the Solid Cable tables as already created.
# The actual tables are created from cable_schema.rb on initial setup.
# This prevents Rails from trying to run db:schema:load on production.
class CreateSolidCableTables < ActiveRecord::Migration[8.1]
  def change
    # Tables already exist from cable_schema.rb
    # This migration just tracks that they're created
  end
end

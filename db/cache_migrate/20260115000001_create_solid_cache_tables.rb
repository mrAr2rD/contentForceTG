# This migration marks the Solid Cache tables as already created.
# The actual tables are created from cache_schema.rb on initial setup.
# This prevents Rails from trying to run db:schema:load on production.
class CreateSolidCacheTables < ActiveRecord::Migration[8.1]
  def change
    # Tables already exist from cache_schema.rb
    # This migration just tracks that they're created
  end
end

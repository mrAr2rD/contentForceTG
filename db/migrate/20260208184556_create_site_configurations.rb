class CreateSiteConfigurations < ActiveRecord::Migration[8.1]
  def change
    create_table :site_configurations, id: :uuid do |t|
      t.boolean :channel_sites_enabled, default: false, null: false

      t.timestamps
    end
  end
end

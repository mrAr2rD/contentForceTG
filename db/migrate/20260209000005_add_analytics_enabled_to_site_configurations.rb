class AddAnalyticsEnabledToSiteConfigurations < ActiveRecord::Migration[8.1]
  def change
    add_column :site_configurations, :analytics_enabled, :boolean, default: true, null: false
  end
end

class AddTelegramIntegrationEnabledToSiteConfigurations < ActiveRecord::Migration[8.1]
  def change
    add_column :site_configurations, :telegram_integration_enabled, :boolean, default: false, null: false
  end
end

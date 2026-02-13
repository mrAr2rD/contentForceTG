class AddAnalyticsToSiteConfiguration < ActiveRecord::Migration[8.1]
  def change
    add_column :site_configurations, :yandex_metrika_id, :string
    add_column :site_configurations, :google_analytics_id, :string
    add_column :site_configurations, :default_og_image, :string
    add_column :site_configurations, :site_name, :string
  end
end

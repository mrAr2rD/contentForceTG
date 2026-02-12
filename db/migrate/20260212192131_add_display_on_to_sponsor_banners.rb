class AddDisplayOnToSponsorBanners < ActiveRecord::Migration[8.1]
  def change
    add_column :sponsor_banners, :display_on, :integer, default: 0, null: false
    add_index :sponsor_banners, [:enabled, :display_on]
  end
end

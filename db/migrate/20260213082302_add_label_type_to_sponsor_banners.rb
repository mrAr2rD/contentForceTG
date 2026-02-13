class AddLabelTypeToSponsorBanners < ActiveRecord::Migration[8.1]
  def change
    add_column :sponsor_banners, :label_type, :integer, default: 0, null: false
  end
end

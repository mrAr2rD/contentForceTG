class CreateSponsorBanners < ActiveRecord::Migration[8.1]
  def change
    create_table :sponsor_banners, id: :uuid do |t|
      t.string :title, null: false
      t.text :description
      t.string :url, null: false
      t.boolean :enabled, default: false, null: false

      t.timestamps
    end

    # Добавляем индекс для быстрого поиска активного баннера
    add_index :sponsor_banners, :enabled
  end
end

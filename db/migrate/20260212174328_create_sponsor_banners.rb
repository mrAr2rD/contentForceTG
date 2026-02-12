class CreateSponsorBanners < ActiveRecord::Migration[8.1]
  def change
    create_table :sponsor_banners, id: :uuid do |t|
      t.string :title, null: false
      t.text :description
      t.string :url, null: false
      t.boolean :enabled, default: false, null: false
      t.integer :display_on, default: 0, null: false # 0 = public_pages, 1 = dashboard

      t.timestamps
    end

    # Добавляем индексы для быстрого поиска активного баннера
    add_index :sponsor_banners, :enabled
    add_index :sponsor_banners, [:enabled, :display_on]
  end
end

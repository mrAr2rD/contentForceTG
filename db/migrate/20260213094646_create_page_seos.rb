class CreatePageSeos < ActiveRecord::Migration[8.1]
  def change
    create_table :page_seos, id: :uuid do |t|
      t.string :slug
      t.string :title
      t.text :description
      t.string :og_title
      t.text :og_description
      t.string :canonical_url

      t.timestamps
    end
    add_index :page_seos, :slug, unique: true
  end
end

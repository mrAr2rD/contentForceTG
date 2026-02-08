# frozen_string_literal: true

class CreateArticles < ActiveRecord::Migration[8.1]
  def change
    create_table :articles, id: :uuid do |t|
      t.string :title, null: false
      t.string :slug, null: false
      t.text :content, null: false
      t.text :excerpt
      t.string :meta_title
      t.text :meta_description
      t.integer :status, default: 0, null: false
      t.datetime :published_at
      t.references :author, type: :uuid, null: false, foreign_key: { to_table: :users }
      t.string :category
      t.jsonb :tags, default: []
      t.integer :views_count, default: 0
      t.integer :reading_time

      t.timestamps
    end

    add_index :articles, :slug, unique: true
    add_index :articles, :status
    add_index :articles, :published_at
    add_index :articles, :category
  end
end

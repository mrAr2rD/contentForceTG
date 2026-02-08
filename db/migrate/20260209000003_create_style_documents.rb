# frozen_string_literal: true

class CreateStyleDocuments < ActiveRecord::Migration[8.1]
  def change
    create_table :style_documents, id: :uuid do |t|
      t.references :project, type: :uuid, null: false, foreign_key: true

      t.string :filename, null: false
      t.text :content, null: false
      t.string :content_type
      t.integer :file_size
      t.boolean :used_for_analysis, default: true

      t.timestamps
    end

    add_index :style_documents, :used_for_analysis
  end
end

# frozen_string_literal: true

class CreateStyleSamples < ActiveRecord::Migration[8.1]
  def change
    create_table :style_samples, id: :uuid do |t|
      t.references :project, type: :uuid, null: false, foreign_key: true

      t.text :content, null: false
      t.string :source_type              # telegram_import, manual, file_upload
      t.string :source_channel           # username канала для telegram_import
      t.bigint :telegram_message_id      # ID сообщения в Telegram
      t.datetime :original_date          # Дата оригинального поста
      t.jsonb :metadata, default: {}
      t.boolean :used_for_analysis, default: true

      t.timestamps
    end

    add_index :style_samples, :source_type
    add_index :style_samples, :used_for_analysis
    add_index :style_samples, [:project_id, :telegram_message_id],
              unique: true,
              where: "telegram_message_id IS NOT NULL",
              name: "idx_style_samples_project_message_unique"
  end
end

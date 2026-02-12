# frozen_string_literal: true

# Шаблоны уведомлений для разных типов событий
class CreateNotificationTemplates < ActiveRecord::Migration[8.1]
  def change
    create_table :notification_templates, id: :uuid do |t|
      t.string :event_type, null: false          # payment_success, subscription_expiring, etc.
      t.string :channel, null: false             # email, telegram
      t.string :subject                          # Тема для email
      t.text :body_template, null: false         # Шаблон с переменными типа {{user_name}}
      t.boolean :active, default: true           # Активен ли шаблон

      t.timestamps
    end

    add_index :notification_templates, [ :event_type, :channel ], unique: true
    add_index :notification_templates, :active
  end
end

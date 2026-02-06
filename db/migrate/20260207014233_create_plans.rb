# frozen_string_literal: true

# Миграция для создания таблицы тарифных планов
# Заменяет хардкод PLAN_PRICES и PLAN_LIMITS в subscription.rb
class CreatePlans < ActiveRecord::Migration[8.1]
  def change
    create_table :plans, id: :uuid do |t|
      t.string :slug, null: false              # free, starter, pro, business
      t.string :name, null: false              # Отображаемое название
      t.decimal :price, precision: 10, scale: 2, default: 0 # Цена в рублях
      t.jsonb :limits, default: {}             # Лимиты: projects, bots, posts_per_month, ai_generations
      t.jsonb :features, default: {}           # Фичи: analytics уровень и т.д.
      t.integer :position, default: 0          # Порядок отображения
      t.boolean :active, default: true         # Активен ли план для новых подписок

      t.timestamps
    end

    add_index :plans, :slug, unique: true
    add_index :plans, :active
    add_index :plans, :position
  end
end

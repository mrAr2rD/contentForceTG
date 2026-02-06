# frozen_string_literal: true

# Добавляет связь subscription -> plan для динамических тарифов
class AddPlanIdToSubscriptions < ActiveRecord::Migration[8.1]
  def change
    add_reference :subscriptions, :plan, type: :uuid, foreign_key: true, null: true
  end
end

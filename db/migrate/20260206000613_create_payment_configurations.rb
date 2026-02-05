class CreatePaymentConfigurations < ActiveRecord::Migration[8.1]
  def change
    create_table :payment_configurations, id: :uuid do |t|
      t.string :merchant_login
      t.string :password_1
      t.string :password_2
      t.boolean :test_mode, default: true, null: false
      t.boolean :enabled, default: false, null: false

      t.timestamps
    end
  end
end

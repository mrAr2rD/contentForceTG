class CreatePayments < ActiveRecord::Migration[8.1]
  def change
    create_table :payments, id: :uuid do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.references :subscription, null: false, foreign_key: true, type: :uuid
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.integer :status, null: false, default: 0
      t.string :provider, null: false
      t.string :provider_payment_id
      t.jsonb :metadata, default: {}
      t.datetime :paid_at

      t.timestamps
    end

    add_index :payments, :provider_payment_id
    add_index :payments, :status
    add_index :payments, [ :user_id, :created_at ]
  end
end

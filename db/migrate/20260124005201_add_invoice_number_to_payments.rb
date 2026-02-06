# frozen_string_literal: true

class AddInvoiceNumberToPayments < ActiveRecord::Migration[8.1]
  def change
    add_column :payments, :invoice_number, :integer
    add_index :payments, :invoice_number, unique: true

    # Populate existing payments with sequential invoice numbers
    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE payments 
          SET invoice_number = subquery.row_num 
          FROM (
            SELECT id, ROW_NUMBER() OVER (ORDER BY created_at) as row_num 
            FROM payments
          ) as subquery 
          WHERE payments.id = subquery.id
        SQL
      end
    end
  end
end

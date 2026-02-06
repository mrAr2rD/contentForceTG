class ChangeInvoiceNumberToBigint < ActiveRecord::Migration[8.1]
  def up
    change_column :payments, :invoice_number, :bigint
  end

  def down
    change_column :payments, :invoice_number, :integer
  end
end

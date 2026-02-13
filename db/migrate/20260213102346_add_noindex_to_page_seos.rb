class AddNoindexToPageSeos < ActiveRecord::Migration[8.1]
  def change
    add_column :page_seos, :noindex, :boolean, default: false, null: false
  end
end

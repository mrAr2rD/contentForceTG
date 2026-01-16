class AddPostTypeFieldsToPosts < ActiveRecord::Migration[8.1]
  def change
    add_column :posts, :post_type, :integer, default: 0, null: false
    add_column :posts, :button_text, :string
    add_column :posts, :button_url, :string

    add_index :posts, :post_type
  end
end

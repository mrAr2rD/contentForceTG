class AddPostTypeFieldsToPosts < ActiveRecord::Migration[8.1]
  def change
    # Add columns only if they don't exist
    add_column :posts, :post_type, :integer, default: 0, null: false unless column_exists?(:posts, :post_type)
    add_column :posts, :button_text, :string unless column_exists?(:posts, :button_text)
    add_column :posts, :button_url, :string unless column_exists?(:posts, :button_url)

    # Add index only if it doesn't exist
    add_index :posts, :post_type unless index_exists?(:posts, :post_type)
  end
end

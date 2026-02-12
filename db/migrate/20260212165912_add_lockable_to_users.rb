class AddLockableToUsers < ActiveRecord::Migration[8.1]
  def change
    # Devise :lockable поля для защиты от brute force атак
    add_column :users, :failed_attempts, :integer, default: 0, null: false
    add_column :users, :unlock_token, :string
    add_column :users, :locked_at, :datetime

    # Индекс для эффективного поиска по unlock_token
    add_index :users, :unlock_token, unique: true
  end
end

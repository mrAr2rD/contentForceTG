class AddOnboardingFieldsToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :referral_source, :string
    add_column :users, :age_range, :string
    add_column :users, :occupation, :string
    add_column :users, :company_size, :string
    add_column :users, :onboarding_completed_at, :datetime
    add_column :users, :onboarding_skipped_at, :datetime

    add_index :users, :referral_source
    add_index :users, :age_range
    add_index :users, :occupation
    add_index :users, :company_size
  end
end

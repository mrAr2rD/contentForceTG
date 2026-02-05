# frozen_string_literal: true

class AddErrorDetailsToPosts < ActiveRecord::Migration[8.1]
  def change
    add_column :posts, :error_details, :text
  end
end

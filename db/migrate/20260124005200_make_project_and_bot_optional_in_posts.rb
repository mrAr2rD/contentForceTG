# frozen_string_literal: true

class MakeProjectAndBotOptionalInPosts < ActiveRecord::Migration[8.1]
  def change
    change_column_null :posts, :project_id, true
    change_column_null :posts, :telegram_bot_id, true
  end
end

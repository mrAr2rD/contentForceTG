class ChangeProjectIdToOptionalInPosts < ActiveRecord::Migration[8.1]
  def change
    change_column_null :posts, :project_id, true
  end
end

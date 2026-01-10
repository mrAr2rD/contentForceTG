class CreateProjects < ActiveRecord::Migration[8.0]
  def change
    create_table :projects, id: :uuid do |t|
      t.string :name
      t.text :description
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.integer :status

      t.timestamps
    end
  end
end

# frozen_string_literal: true

class AddCustomStyleToProjects < ActiveRecord::Migration[8.1]
  def change
    add_column :projects, :custom_style_enabled, :boolean, default: false
    add_column :projects, :custom_style_prompt, :text
    add_column :projects, :style_analysis_status, :integer, default: 0
    add_column :projects, :style_analyzed_at, :datetime
  end
end

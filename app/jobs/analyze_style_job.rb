# frozen_string_literal: true

class AnalyzeStyleJob < ApplicationJob
  queue_as :default

  def perform(project_id)
    project = Project.find_by(id: project_id)
    return unless project

    analyzer = Ai::StyleAnalyzer.new(project)
    result = analyzer.analyze!

    if result[:success]
      Rails.logger.info "Style analysis completed for project #{project_id}"
    else
      Rails.logger.error "Style analysis failed for project #{project_id}: #{result[:error]}"
    end
  end
end

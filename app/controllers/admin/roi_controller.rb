# frozen_string_literal: true

module Admin
  class RoiController < Admin::ApplicationController
    def index
      @period = params[:period]&.to_i || 30
      @calculator = Analytics::RoiCalculatorService.new(period: @period.days)
      @roi_data = @calculator.calculate
    rescue StandardError => e
      Rails.logger.error("Failed to calculate ROI: #{e.message}")
      @roi_data = nil
      @roi_error = "Не удалось загрузить ROI данные: #{e.message}"
    end
  end
end

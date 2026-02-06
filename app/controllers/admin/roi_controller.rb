# frozen_string_literal: true

module Admin
  class RoiController < Admin::ApplicationController
    def index
      @period = params[:period]&.to_i || 30
      @calculator = Analytics::RoiCalculatorService.new(period: @period.days)
      @roi_data = @calculator.calculate
    end
  end
end

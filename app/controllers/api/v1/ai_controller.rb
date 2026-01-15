# frozen_string_literal: true

module Api
  module V1
    class AiController < ApplicationController
      skip_before_action :verify_authenticity_token
      before_action :authenticate_user!

      def generate
        project = current_user.projects.find_by(id: params[:project_id])
        
        generator = Ai::ContentGenerator.new(project: project, user: current_user)
        result = generator.generate(
          prompt: params[:prompt],
          context: {
            tone_of_voice: params[:tone_of_voice],
            model: params[:model]
          }
        )

        if result[:success]
          render json: {
            success: true,
            content: result[:content],
            model_used: result[:model_used],
            tokens_used: result[:tokens_used]
          }
        else
          render json: {
            success: false,
            error: result[:error]
          }, status: :unprocessable_entity
        end
      end

      def improve
        generator = Ai::ContentGenerator.new(user: current_user)
        result = generator.improve(
          content: params[:content],
          instruction: params[:instruction]
        )

        if result[:success]
          render json: {
            success: true,
            content: result[:content]
          }
        else
          render json: {
            success: false,
            error: result[:error]
          }, status: :unprocessable_entity
        end
      end

      def generate_hashtags
        generator = Ai::ContentGenerator.new(user: current_user)
        result = generator.generate_hashtags(
          content: params[:content],
          count: params[:count] || 5
        )

        if result[:success]
          render json: {
            success: true,
            hashtags: result[:hashtags]
          }
        else
          render json: {
            success: false,
            error: result[:error]
          }, status: :unprocessable_entity
        end
      end
    end
  end
end

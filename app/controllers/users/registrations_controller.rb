# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  layout :resolve_layout

  private

  def resolve_layout
    if action_name == "edit" || action_name == "update"
      "dashboard"
    else
      "application"
    end
  end
end

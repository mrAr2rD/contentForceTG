# frozen_string_literal: true

class TelegramSession < ApplicationRecord
  # Associations
  belongs_to :user

  # Encryption
  encrypts :session_string

  # Validations
  validates :session_string, presence: true
  validates :phone_number, format: { with: /\A\+?[0-9]{10,15}\z/, message: "должен быть валидным номером телефона" }, allow_blank: true

  # Scopes
  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }

  # Deactivate session
  def deactivate!
    update!(active: false)
  end

  # Activate session
  def activate!
    update!(active: true)
  end
end

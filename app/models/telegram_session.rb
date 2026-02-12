# frozen_string_literal: true

class TelegramSession < ApplicationRecord
  # Associations
  belongs_to :user

  # Encryption
  encrypts :session_string
  encrypts :phone_code_hash

  # Enums
  enum :auth_status, {
    pending_code: 0,
    pending_2fa: 1,
    auth_active: 2,
    auth_expired: 3
  }, prefix: :auth

  # Validations
  validates :session_string, presence: true, if: :auth_auth_active?
  validates :phone_number, presence: true
  validates :phone_number, format: { with: /\A\+?[0-9]{10,15}\z/, message: "должен быть валидным номером телефона" }

  # Scopes
  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
  scope :authorized, -> { where(auth_status: :auth_active) }
  scope :pending, -> { where(auth_status: [ :pending_code, :pending_2fa ]) }

  # Callbacks
  before_create :set_auth_expiration

  # Deactivate session
  def deactivate!
    update!(active: false)
  end

  # Activate session
  def activate!
    update!(active: true)
  end

  # Check if auth code expired
  def auth_expired?
    auth_expires_at.present? && auth_expires_at < Time.current
  end

  # Complete authorization
  def complete_authorization!(session_string_value)
    update!(
      session_string: session_string_value,
      auth_status: :auth_active,
      active: true,
      phone_code_hash: nil,
      auth_expires_at: nil
    )
  end

  # Set pending 2FA
  def require_2fa!
    update!(auth_status: :pending_2fa)
  end

  # Expire session
  def expire!
    update!(auth_status: :auth_expired, active: false)
  end

  # Masked phone number for display
  def masked_phone
    return phone_number if phone_number.blank?
    phone_number.gsub(/(\+?\d{1,3})(\d+)(\d{2})/) { "#{$1}#{'*' * $2.length}#{$3}" }
  end

  private

  def set_auth_expiration
    self.auth_expires_at ||= 5.minutes.from_now if auth_pending_code?
  end
end

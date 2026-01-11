class TelegramBot < ApplicationRecord
  # Associations
  belongs_to :project
  has_many :posts, dependent: :nullify

  # Encryption
  encrypts :bot_token

  # Validations
  validates :bot_token, presence: true
  validates :bot_username, presence: true, uniqueness: true
  validates :channel_id, presence: true

  # Scopes
  scope :verified, -> { where(verified: true) }
  scope :unverified, -> { where(verified: false) }
  scope :recent, -> { order(created_at: :desc) }

  # Callbacks
  before_validation :extract_bot_username, if: -> { bot_token.present? && bot_username.blank? }

  # Instance methods
  def verify!
    return if verified?

    # Verification logic will be implemented in Telegram::VerifyService
    update!(
      verified: true,
      verified_at: Time.current
    )
  end

  def verified?
    verified == true
  end

  def unverified?
    !verified?
  end

  def display_name
    bot_username || channel_name || "Bot ##{id.first(8)}"
  end

  private

  def extract_bot_username
    # Extract username from bot_token if possible
    # Format: 123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11
    # This is just a placeholder - actual extraction would need Bot API
    self.bot_username ||= "bot_#{SecureRandom.hex(4)}"
  end
end

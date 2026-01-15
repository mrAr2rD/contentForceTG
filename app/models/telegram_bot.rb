class TelegramBot < ApplicationRecord
  # Associations
  belongs_to :project
  has_many :posts, dependent: :nullify

  # Encryption - временно отключено для разработки
  # encrypts :bot_token

  # Validations
  validates :bot_token, presence: true
  validates :bot_username, presence: true, uniqueness: { case_sensitive: false }
  validates :channel_id, presence: true

  # Scopes
  scope :verified, -> { where(verified: true) }
  scope :unverified, -> { where(verified: false) }
  scope :recent, -> { order(created_at: :desc) }

  # Callbacks
  before_validation :extract_bot_username, if: -> { bot_token.present? && bot_username.blank? }
  after_create :setup_webhook, if: -> { verified? }

  # Instance methods
  def verify!
    return if verified?

    Telegram::VerifyService.new(self).verify!
  rescue StandardError => e
    Rails.logger.error("Failed to verify bot #{id}: #{e.message}")
    raise
  end

  def setup_webhook!
    Telegram::WebhookService.new(self).setup!
  rescue StandardError => e
    Rails.logger.error("Failed to setup webhook for bot #{id}: #{e.message}")
    raise
  end

  def setup_webhook
    setup_webhook! if verified?
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

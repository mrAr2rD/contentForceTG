class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :timeoutable and :omniauthable
  # Note: :confirmable is disabled for easier development
  # SECURITY: :lockable включён для защиты от brute force атак
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :trackable, :lockable,
         :omniauthable, omniauth_providers: [ :telegram ]

  # Enums
  enum :role, { user: 0, admin: 1 }, default: :user

  # Associations
  has_many :projects, dependent: :destroy
  has_many :posts, dependent: :destroy
  has_one :subscription, dependent: :destroy
  has_many :payments, dependent: :destroy
  has_many :telegram_sessions, dependent: :destroy

  # Validations
  validates :email, presence: true, uniqueness: true, allow_blank: true
  validates :telegram_id, uniqueness: true, allow_nil: true
  validates :role, presence: true
  validates :time_zone, presence: true, inclusion: {
    in: ActiveSupport::TimeZone.all.map(&:name),
    message: "некорректная временная зона"
  }

  # Callbacks
  after_create :create_default_subscription, if: -> { subscription.nil? }

  # Helper method for admin check
  def admin?
    role == "admin"
  end

  # Class methods
  def self.from_telegram_auth(auth_data)
    # Проверяем подлинность данных от Telegram
    unless verify_telegram_auth_data(auth_data)
      Rails.logger.error("Telegram OAuth: Invalid signature for user ID #{auth_data['id']}")
      raise SecurityError, "Invalid Telegram authentication data"
    end

    user = find_or_initialize_by(telegram_id: auth_data["id"])
    user.assign_attributes(
      telegram_username: auth_data["username"],
      first_name: auth_data["first_name"],
      last_name: auth_data["last_name"],
      avatar_url: auth_data["photo_url"],
      email: auth_data["email"] || "telegram_#{auth_data['id']}@contentforce.local",
      time_zone: user.time_zone.presence || "Moscow"
    )

    # Skip password validation for Telegram users
    user.password = Devise.friendly_token[0, 20] if user.new_record?

    # Auto-confirm Telegram users
    user.skip_confirmation! if user.respond_to?(:skip_confirmation!)

    user.save!
    user
  end

  # Проверка подлинности данных Telegram OAuth через HMAC-SHA256
  def self.verify_telegram_auth_data(auth_data)
    received_hash = auth_data["hash"]
    return false if received_hash.blank?

    # Проверяем свежесть данных (максимум 24 часа)
    auth_date = auth_data["auth_date"].to_i
    if auth_date < 24.hours.ago.to_i
      Rails.logger.warn("Telegram OAuth: Auth data too old (#{Time.at(auth_date)})")
      return false
    end

    # Строим data_check_string (параметры в алфавитном порядке, кроме hash)
    data_check_arr = auth_data.except("hash").map { |k, v| "#{k}=#{v}" }.sort
    data_check_string = data_check_arr.join("\n")

    # Вычисляем secret key из bot token
    bot_token = ENV.fetch("TELEGRAM_BOT_TOKEN")
    secret_key = Digest::SHA256.digest(bot_token)

    # Вычисляем HMAC-SHA256
    calculated_hash = OpenSSL::HMAC.hexdigest(
      OpenSSL::Digest.new("sha256"),
      secret_key,
      data_check_string
    )

    # Безопасное сравнение для защиты от timing attacks
    ActiveSupport::SecurityUtils.secure_compare(
      received_hash.to_s.downcase,
      calculated_hash.downcase
    )
  end

  private

  def create_default_subscription
    create_subscription!(plan: :free, status: :active) if subscription.nil?
  end

  # Override Devise method to allow Telegram users without password
  def password_required?
    return false if telegram_id.present?
    super
  end

  # Override Devise method to allow Telegram users without email confirmation
  def email_required?
    telegram_id.blank?
  end
end

class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :lockable, :timeoutable and :omniauthable
  # Note: :confirmable is disabled for easier development
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable,
         :trackable,
         :omniauthable, omniauth_providers: [:telegram]

  # Enums
  enum :role, { user: 0, admin: 1 }, default: :user

  # Associations
  has_many :projects, dependent: :destroy
  has_many :posts, dependent: :destroy
  has_one :subscription, dependent: :destroy
  has_many :payments, dependent: :destroy

  # Validations
  validates :email, presence: true, uniqueness: true, allow_blank: true
  validates :telegram_id, uniqueness: true, allow_nil: true
  validates :role, presence: true

  # Callbacks
  after_create :create_default_subscription, if: -> { subscription.nil? }

  # Helper method for admin check
  def admin?
    role == 'admin'
  end

  # Class methods
  def self.from_telegram_auth(auth_data)
    user = find_or_initialize_by(telegram_id: auth_data['id'])
    user.assign_attributes(
      telegram_username: auth_data['username'],
      first_name: auth_data['first_name'],
      last_name: auth_data['last_name'],
      avatar_url: auth_data['photo_url'],
      email: auth_data['email'] || "telegram_#{auth_data['id']}@contentforce.local"
    )

    # Skip password validation for Telegram users
    user.password = Devise.friendly_token[0, 20] if user.new_record?

    # Auto-confirm Telegram users
    user.skip_confirmation! if user.respond_to?(:skip_confirmation!)

    user.save!
    user
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

class Project < ApplicationRecord
  # Associations
  belongs_to :user
  has_many :posts, dependent: :destroy
  has_many :telegram_bots, dependent: :destroy

  # Enums
  enum :status, { draft: 0, active: 1, archived: 2 }, default: :draft

  # Validations
  validates :name, presence: true, length: { minimum: 2, maximum: 100 }
  validates :description, length: { maximum: 1000 }, allow_blank: true

  # Scopes
  scope :active, -> { where(status: :active) }
  scope :archived, -> { where(status: :archived) }
  scope :recent, -> { order(updated_at: :desc) }

  # Instance methods
  def archive!
    update!(status: :archived)
  end

  def activate!
    update!(status: :active)
  end

  def archived?
    status == "archived"
  end

  def active?
    status == "active"
  end

  def draft?
    status == "draft"
  end
end

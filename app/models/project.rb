class Project < ApplicationRecord
  belongs_to :user
  has_many :posts, dependent: :destroy

  enum :status, { draft: 0, active: 1, archived: 2 }, default: :draft

  validates :name, presence: true
end

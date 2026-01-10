class Post < ApplicationRecord
  belongs_to :user
  belongs_to :project, optional: true

  enum :status, { draft: 0, scheduled: 1, published: 2, failed: 3 }, default: :draft

  validates :title, presence: true
  validates :content, presence: true
end

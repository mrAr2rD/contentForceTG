# frozen_string_literal: true

class Payment < ApplicationRecord
  # Associations
  belongs_to :user
  belongs_to :subscription

  # Enums
  enum :status, {
    pending: 0,
    processing: 1,
    completed: 2,
    failed: 3,
    refunded: 4,
    canceled: 5
  }, default: :pending

  # Callbacks
  before_create :generate_invoice_number

  # Validations
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :provider, presence: true
  validates :status, presence: true

  # Scopes
  scope :completed, -> { where(status: :completed) }
  scope :pending, -> { where(status: :pending) }
  scope :recent, -> { order(created_at: :desc) }

  # Instance methods
  def mark_as_completed!
    update!(
      status: :completed,
      paid_at: Time.current
    )
  end

  def mark_as_failed!
    update!(status: :failed)
  end

  def completed?
    status == 'completed'
  end

  def pending?
    status == 'pending'
  end

  def refund!
    return false unless completed?

    update!(status: :refunded)
  end

  # Human-readable status
  def status_name
    I18n.t("payments.statuses.#{status}", default: status.humanize)
  end

  private

  def generate_invoice_number
    max_invoice = Payment.maximum(:invoice_number) || 0
    self.invoice_number = max_invoice + 1
  end
end

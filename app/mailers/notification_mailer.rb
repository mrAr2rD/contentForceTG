# frozen_string_literal: true

class NotificationMailer < ApplicationMailer
  def deliver_notification(notification)
    @notification = notification
    @user = notification.user

    mail(
      to: @user.email,
      subject: notification.subject || 'Уведомление от ContentForce'
    ) do |format|
      format.text { render plain: notification.body }
      format.html { render 'notification' }
    end
  end

  # Метод для отложенной отправки
  def self.deliver_notification(notification)
    new.deliver_notification(notification)
  end
end

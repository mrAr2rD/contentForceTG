class PagesController < ApplicationController
  def home
    @plans = Plan.cached_all
  end

  def terms
    # Terms of service / Public offer
  end

  def privacy
    # Privacy policy
  end

  def about
    # О компании
  end

  def careers
    # Партнёрская программа
  end

  def contacts
    # Контакты и форма обратной связи
  end

  def submit_contact
    # Обработка формы обратной связи
    name = params[:name]
    email = params[:email]
    message = params[:message]

    # TODO: Отправка email через ContactMailer
    # ContactMailer.new_message(name: name, email: email, message: message).deliver_later

    Rails.logger.info "Contact form submission: #{name} (#{email}): #{message}"

    redirect_to contacts_path, notice: 'Ваше сообщение отправлено. Мы свяжемся с вами в ближайшее время.'
  end

  def docs
    # Документация
  end
end

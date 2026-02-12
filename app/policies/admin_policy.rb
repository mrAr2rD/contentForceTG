# frozen_string_literal: true

class AdminPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record

    # Admin policies требуют admin роль
    raise Pundit::NotAuthorizedError unless user&.admin?
  end

  # По умолчанию все действия запрещены для не-админов
  def index?
    user&.admin?
  end

  def show?
    user&.admin?
  end

  def create?
    user&.admin?
  end

  def new?
    create?
  end

  def update?
    user&.admin?
  end

  def edit?
    update?
  end

  def destroy?
    user&.admin?
  end

  # Scope для админ ресурсов (возвращает всё для админов)
  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope

      raise Pundit::NotAuthorizedError unless user&.admin?
    end

    def resolve
      # Админы видят всё
      scope.all
    end
  end
end

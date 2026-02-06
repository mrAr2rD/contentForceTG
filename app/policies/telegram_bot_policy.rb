class TelegramBotPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.admin?
        scope.all
      else
        scope.joins(:project).where(projects: { user_id: user.id })
      end
    end
  end

  def index?
    true
  end

  def show?
    user_owns_project? || user.admin?
  end

  def create?
    user.present?
  end

  def update?
    user_owns_project? || user.admin?
  end

  def destroy?
    user_owns_project? || user.admin?
  end

  def verify?
    user_owns_project? || user.admin?
  end

  def subscriber_analytics?
    user_owns_project? || user.admin?
  end

  private

  def user_owns_project?
    record.project.user_id == user.id
  end
end

class PostPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.admin?
        scope.all
      else
        scope.where(user: user)
      end
    end
  end

  def index?
    true
  end

  def show?
    user_owns_record? || user.admin?
  end

  def create?
    user.present?
  end

  def update?
    user_owns_record? || user.admin?
  end

  def destroy?
    user_owns_record? || user.admin?
  end

  def publish?
    user_owns_record? || user.admin?
  end

  def schedule?
    user_owns_record? || user.admin?
  end

  private

  def user_owns_record?
    record.user_id == user.id
  end
end

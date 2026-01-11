class ProjectPolicy < ApplicationPolicy
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
    true  # Any authenticated user can list their projects
  end

  def show?
    user_owns_record? || user.admin?
  end

  def create?
    user.present?  # Any authenticated user can create projects
  end

  def update?
    user_owns_record? || user.admin?
  end

  def destroy?
    user_owns_record? || user.admin?
  end

  def archive?
    update?
  end

  def activate?
    update?
  end

  private

  def user_owns_record?
    record.user_id == user.id
  end
end

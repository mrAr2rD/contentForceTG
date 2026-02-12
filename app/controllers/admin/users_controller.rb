# frozen_string_literal: true

module Admin
  class UsersController < Admin::ApplicationController
    def index
      @users = User.order(created_at: :desc).page(params[:page]).per(25)
    end

    def show
      @user = User.find(params[:id])
    end

    def edit
      @user = User.find(params[:id])
    end

    def update
      @user = User.find(params[:id])

      # SECURITY: Запрещаем админу изменять собственную роль
      # Это предотвращает самоповышение прав или случайное лишение прав
      if @user == current_user && params[:user][:role].present?
        redirect_to admin_user_path(@user), alert: "Вы не можете изменить собственную роль"
        return
      end

      if @user.update(user_params)
        redirect_to admin_user_path(@user), notice: "Пользователь обновлен"
      else
        render :edit
      end
    end

    def destroy
      @user = User.find(params[:id])

      if @user == current_user
        redirect_to admin_users_path, alert: "Вы не можете удалить себя"
      else
        @user.destroy
        redirect_to admin_users_path, notice: "Пользователь удален"
      end
    end

    private

    def user_params
      # SECURITY: Только админы могут изменять role
      # Проверка прав происходит в Admin::ApplicationController
      params.require(:user).permit(:email, :role)
    end
  end
end

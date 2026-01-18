class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [:home, :terms, :privacy]

  def home
  end

  def terms
    # Terms of service / Public offer
  end

  def privacy
    # Privacy policy
  end
end

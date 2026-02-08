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
end

class ApplicationController < ActionController::Base
  before_action :migrate_legacy_sponsorship_session
  before_action :set_locale

  private

  def set_locale
    session[:hl] = :ja
  end

  helper_method def current_staff
    return @current_staff if defined? @current_staff
    @current_staff = session[:staff_id] && Staff.find_by(id: session[:staff_id])
  end

  helper_method def current_sponsorship
    return @current_sponsorship if defined? @current_sponsorship
    return nil unless params[:conference_slug]
    return nil unless session[:sponsorship_ids]

    @current_sponsorship = Sponsorship.where(id: session[:sponsorship_ids])
      .joins(:conference)
      .merge(Conference.where(slug: params[:conference_slug]))
      .not_withdrawn
      .first
  end

  helper_method def current_available_sponsorships
    return @current_available_sponsorships if defined? @current_available_sponsorships
    return nil unless session[:sponsorship_ids]
    @current_available_sponsorships = Sponsorship.includes(:conference).where(id: session[:sponsorship_ids]).not_withdrawn.order(id: :desc)
  end

  def require_staff
    unless current_staff
      redirect_to new_session_path(back_to: url_for(params.to_unsafe_h.merge(only_path: true)))
    end
  end

  def require_sponsorship_session
    unless current_sponsorship
      redirect_to new_user_session_path(back_to: url_for(params.to_unsafe_h.merge(only_path: true)))
    end
  end

  def migrate_legacy_sponsorship_session
    sponsorship_id = session.delete(:sponsorship_id)
    if sponsorship_id
      session_token = SessionToken.find_by(id: session[:session_token_id])
      session[:sponsorship_ids] = session_token&.sponsorship_ids
    end
  end
end

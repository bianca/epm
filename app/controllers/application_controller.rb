class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  unless Rails.application.config.consider_all_requests_local
    rescue_from Exception do |exception|
      AdminMailer.error_happened(exception, request).deliver if Configurable.webmaster.present?
      render 'shared/500', status: 500
    end
    rescue_from ActiveRecord::RecordNotFound, with: :record_not_found
  end

  check_authorization unless: :devise_controller?
  rescue_from CanCan::AccessDenied do |exception|

   if current_user
       if current_user.has_role?(:tree_registrant) || current_user.has_role?(:tree_owner)
        redirect_to mine_trees_url
        else
          redirect_to root_url, alert: "Sorry, you don't have permission to do that."
        end
   else
     redirect_to new_user_session_url
   end
  end


  protected

    def record_not_found
      render 'shared/404', status: 404
    end

end
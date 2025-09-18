class ApplicationController < ActionController::API
  # API-only application - removed browser-specific configurations
  
  # Optional: Add global error handling for API
  rescue_from ActiveRecord::RecordNotFound, with: :not_found
  rescue_from ActionController::ParameterMissing, with: :bad_request
  
  private
  
  def not_found(exception)
    render json: { error: "Resource not found", message: exception.message }, status: :not_found
  end
  
  def bad_request(exception)
    render json: { error: "Bad request", message: exception.message }, status: :bad_request
  end
end

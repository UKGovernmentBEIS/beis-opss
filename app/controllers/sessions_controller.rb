class SessionsController < ApplicationController
  def new
    redirect_to login_url
  end

  def signin
    request_and_store_token(auth_code)
    flash[:notice] = "Signed in successfully." if KeycloakClient.instance.user_signed_in?
    redirect_to root_path
  rescue RestClient::ExceptionWithResponse => error
    redirect_to new_session_path, alert: signin_error_message(error)
  end

  def logout
    flash[:notice] = "Signed out successfully." if KeycloakClient.instance.logout
    redirect_to root_path
  end

private

  def login_url
    KeycloakClient.instance.login_url(signin_session_url)
  end

  def request_and_store_token(auth_code)
    cookies.permanent[:keycloak_token] = KeycloakClient.instance.exchange_code_for_token(auth_code, signin_session_url)
  end

  def signin_error_message(error)
    error.is_a?(RestClient::Unauthorized) ? "Invalid email or password." : JSON(error.response)["error_description"]
  end

  def auth_code
    params.require(:code)
  end
end

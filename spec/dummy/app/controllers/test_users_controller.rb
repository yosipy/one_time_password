class TestUsersController < ApplicationController
  def new
  end

  def create_auth
    if params[:email].present?
      auth = OneTimePassword::Auth.new(
        OneTimePassword::FUNCTION_NAMES[:sign_up],
        0,
        params[:email]
      )
      one_time_authentication = auth.create_one_time_authentication
    else
      # error
    end
  end

  def create
    if params[:email].present?
      auth = OneTimePassword::Auth.new(
        OneTimePassword::FUNCTION_NAMES[:sign_up],
        0,
        params[:email]
      )
      one_time_authentication = auth.find_one_time_authentication
    end
  end
end

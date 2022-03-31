class TestUsersController < ApplicationController
  def create_one_time_auth
    if params[:email].blank?
      # error
      # Please enter your email address.
      return render :json => {}, status: 400
    end

    context = OneTimeAuthentication.find_context(
      OneTimePassword::FUNCTION_NAMES[:sign_up]
    )
    one_time_authentication = OneTimeAuthentication.create_one_time_authentication(
      context,
      params[:email].downcase
    )
    if one_time_authentication.present?
      # success
      # Send one_time_password to user with email or sms.
      # And returns client_token to the client.
      OneTimePasswordMailer.send_one_time_password(params[:email].downcase, one_time_authentication.password).deliver_now
      render :json => {
        client_token: one_time_authentication.client_token
      }, status: 200
    else
      # error
      # The maximum number of passwords that can be generated in a given time has been reached
      render :json => {}, status: 401
    end
  end

  def create
    if params[:email].blank?
      # error
      # Please enter your email address.
      return render :json => {}, status: 400
    end

    context = OneTimeAuthentication.find_context(
      OneTimePassword::FUNCTION_NAMES[:sign_up]
    )
    one_time_authentication = OneTimeAuthentication.find_one_time_authentication(
      context,
      params[:email].downcase
    )
    new_client_token = one_time_authentication.authenticate_one_time_client_token!(params[:client_token])
    if new_client_token
      if one_time_authentication.authenticate_one_time_password!(params[:one_time_password])
        # success
        sign_up(one_time_authentication.user_key, params[:user_password])  # example helper method
        return render :json => {}, status: 200
      else
        if one_time_authentication.under_valid_failed_count?
          # Please reauthentication.
          return render :json => {
            client_token: new_client_token
          }, status: 401
        else
          # error
          # Over valid failed_count
          return render :json => {}, status: 401
        end
      end
    end

    # error
    return render :json => {}, status: 401
  rescue => e
    # error
    return render :json => {}, status: 401
  end
end

module OneTimePassword
  # Example: has sign_up, sign_in and change_email.
  # Please rewrite!

  # Using function_name in OneTimeAuthentication Model enum.
  # ```
  # # app/models/one_time_authentication.rb
  # class OneTimeAuthentication < ActiveRecord::Base
  #   enum function_name: OneTimePassword::FUNCTION_NAMES
  
  #   include OneTimePassword::OneTimeAuthenticationModel
  # end
  # ```
  FUNCTION_NAMES = {
    sign_up: 0, sign_in: 1, change_email: 2
  }

  # {
  #   function_name (Symbol): Name each function.
  #   expires_in (ActiveSupport::Duration): Password validity time.
  #   max_authenticate_password_count (Integer): Number of times user can enter password each generated password.
  #   password_length (Integer): Password length. At 6, for example, the password would be 123456.
  #   password_failed_limit (Integer) & password_failed_period (ActiveSupport::Duration):
  #     If you try to authenticate with the wrong password a password_failed_limit times
  #     within the time set by password_failed_period, you will not be able to generate a new password.
  # }
  CONTEXTS = [
    {
      function_name: :sign_up,
      expires_in: 30.minutes,
      max_authenticate_password_count: 5,
      password_length: 6,
      password_failed_limit: 10,
      password_failed_period: 1.hour
    },
    {
      function_name: :sign_in,
      expires_in: 30.minutes,
      max_authenticate_password_count: 5,
      password_length: 10,
      password_failed_limit: 10,
      password_failed_period: 1.hour
    },
    # {
    #   function_name: :change_email,
    #   expires_in: 30.minutes,
    #   max_authenticate_password_count: 5,
    #   password_length: 6
    # },
  ]
end

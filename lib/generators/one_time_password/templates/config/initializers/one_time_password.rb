module OneTimePassword
  # Example: has sign_up, sign_in and change_email

  # Using function_name in OneTimeAuthentication Model enum.
  # ```
  # # app/models/one_time_authentication.rb
  # class OneTimeAuthentication < OneTimePassword::Models::OneTimeAuthentication
  #   enum function_name: OneTimePassword::FUNCTION_NAMES
  # end
  # ```
  FUNCTION_NAMES = {
    sign_up: 0, sign_in: 1, change_email: 2  # Please rewrite
  }

  # {
  #   function_name: Name each function.(Symbol)
  #   version: Version each function_name.(Integer)
  #   expires_in: Password validity time.(ActiveSupport::Duration)
  #   max_authenticate_password_count: Number of times user can enter password each generated password.(Integer)
  #   password_length: Password length. At 6, for example, the password would be 123456.(Integer)
  #   password_failed_limit:
  #     If you try to authenticate with the wrong password a password_failed_limit times
  #     within the time set by password_failed_period, you will not be able to generate a new password.
  # }
  CONTEXTS = [
    {
      function_name: FUNCTION_NAMES[:sign_up],
      version: 0,
      expires_in: 30.minutes,
      max_authenticate_password_count: 5,
      password_length: 6,
      password_failed_limit: 10,
      password_failed_period: 1.hour
    },
    {
      function_name: FUNCTION_NAMES[:sign_in],
      version: 0,
      expires_in: 30.minutes,
      max_authenticate_password_count: 5,
      password_length: 10,
      password_failed_limit: 10,
      password_failed_period: 1.hour
    },
    # {
    #   function_name: FUNCTION_NAMES[:change_email],
    #   version: 0,
    #   expires_in: 30.minutes,
    #   max_authenticate_password_count: 5,
    #   password_length: 6
    # },
  ]
end

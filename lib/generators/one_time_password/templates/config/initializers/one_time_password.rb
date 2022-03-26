module OneTimePassword
  # Example: has sign_up, sign_in and change_email

  # using function_name in OneTimeAuthentication Model.
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
  #   function_name: OneTimeAuthentication's function_name index.(Integer)
  #   version: Version each function_name.(String)
  #   expires_in: (ActiveSupport::Duration)
  #   max_count: Number of times you can enter your password.(Integer)
  #   password_length: Password length.At 6, for example, the password would be 123456.(Integer)
  # }
  CONTEXTS = [
    {
      function_name: FUNCTION_NAMES[:sign_up],
      version: 0,
      expires_in: 30.minutes,
      max_count: 5,
      password_length: 6,
      password_failed_limit: 10,
      password_failed_period: 1.hour
    },
    {
      function_name: FUNCTION_NAMES[:sign_in],
      version: 0,
      expires_in: 30.minutes,
      max_count: 5,
      password_length: 10,
      password_failed_limit: 10,
      password_failed_period: 1.hour
    },
    # {
    #   function_name: FUNCTION_NAMES[:change_email],
    #   version: 0,
    #   expires_in: 30.minutes,
    #   max_count: 5,
    #   password_length: 6
    # },
  ]
end

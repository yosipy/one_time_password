module OneTimePassword
  class Auth
    def initialize(
      function_name, version, user_key
    )
      @function_name = function_name
      @version = version
      @user_key = user_key
      @context = OneTimeAuthentication.find_context(@function_name, @version)
    end

    def authenticate_password(password)
      result =
        if !expired? && under_valid_failed_count?
          !!@one_time_authentication.authenticate(password)
        else
          false
        end

      if result
        @one_time_authentication.authenticated_at = Time.zone.now
        # Put invalid token(nil) in client_token, and return nil
        @one_time_authentication.client_token = nil
      else
        @one_time_authentication.failed_count += 1
      end
      @one_time_authentication.save!

      result
    end
  end
end

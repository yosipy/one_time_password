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

    def find_one_time_authentication
      @one_time_authentication = OneTimeAuthentication
        .where(function_name: @function_name)
        .where(version: @version)
        .where(user_key: @user_key)
        .last
    end

    def expired?
      expires_seconds = @one_time_authentication.expires_seconds
      created_at = @one_time_authentication.created_at

      !(created_at.to_f <= Time.now.to_f && Time.now.to_f <= created_at.to_f + expires_seconds.to_f)
    end

    def under_valid_failed_count?
      @one_time_authentication.failed_count < @one_time_authentication.max_authenticate_password_count
    end

    def authenticate_client_token(client_token)
      if (@one_time_authentication.client_token.present? &&
          @one_time_authentication.client_token == client_token)
        # Refresh client_token, and return this token
        new_client_token = @one_time_authentication.set_client_token
        @one_time_authentication.save!
        new_client_token
      else
        # Put invalid token(nil) in client_token, and return nil
        @one_time_authentication.client_token = nil
        @one_time_authentication.save!
        nil
      end
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

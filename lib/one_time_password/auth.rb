module OneTimePassword
  class Auth
    def self.find_context(function_name, version)
      context = OneTimePassword::CONTEXTS
        .select{ |context|
          context[:function_name] == function_name &&
            context[:version] == version
        }
        .first

      if context.nil?
        raise ArgumentError.new('Not found context.')
      elsif context[:expires_in].class != ActiveSupport::Duration
        raise RuntimeError.new('Mistake OneTimePassword::CONTEXTS[:expires_in]')
      elsif context[:max_count].class != Integer
        raise RuntimeError.new('Mistake OneTimePassword::CONTEXTS[:max_count]')
      elsif context[:password_length].class != Integer
        raise RuntimeError.new('Mistake OneTimePassword::CONTEXTS[:password_length]')
      elsif context[:password_failed_limit].class != Integer
        raise RuntimeError.new('Mistake OneTimePassword::CONTEXTS[:password_failed_limit]')
      elsif context[:password_failed_period].class != ActiveSupport::Duration
        raise RuntimeError.new('Mistake OneTimePassword::CONTEXTS[:password_failed_period]')
      end

      context
    end

    def initialize(
      function_name, version, user_key
    )
      @function_name = function_name
      @version = version
      @user_key = user_key
      @context = self.class.find_context(@function_name, @version)
    end

    def create_one_time_authentication
      recent_failed_password_count =
        OneTimeAuthentication
          .where(user_key: @user_key)
          .recent_failed_password(@context[:password_failed_period])
          .count
      if recent_failed_password_count <= @context[:password_failed_limit]
        @one_time_authentication = OneTimeAuthentication.new(
          function_name: @function_name,
          version: @version,
          user_key: @user_key,
          password_length: @context[:password_length],
          expires_seconds: @context[:expires_in].to_i,
          max_count: @context[:max_count],
        )
        @one_time_authentication.set_password_and_password_length(@context[:password_length])
        @one_time_authentication.save!
      else
        @one_time_authentication = nil
      end

      @one_time_authentication
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

    def under_valid_count?
      @one_time_authentication.count < @one_time_authentication.max_count
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
        if !expired? && under_valid_count?
          !!@one_time_authentication.authenticate(password)
        else
          false
        end

      if result
        @one_time_authentication.authenticated_at = Time.zone.now
        # Put invalid token(nil) in client_token, and return nil
        @one_time_authentication.client_token = nil
      end
      @one_time_authentication.count += 1
      @one_time_authentication.save!

      result
    end
  end
end

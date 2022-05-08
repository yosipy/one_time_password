module OneTimePassword
  module OneTimeAuthenticationModel
    extend ActiveSupport::Concern

    included do
      before_create :set_client_token

      has_secure_password

      scope :unauthenticated, -> {
        where(authenticated_at: nil)
      }

      scope :recent, -> (time_ago) {
        where(created_at: Time.zone.now.ago(time_ago)...)
      }
    end

    module ClassMethods
      def find_context(function_name)
        context = OneTimePassword::CONTEXTS
          .select{ |context|
            context[:function_name] == function_name
          }
          .first

        if context.nil?
          raise ArgumentError, 'Not found context.'
        elsif context[:expires_in].class != ActiveSupport::Duration
          raise RuntimeError, 'Mistake OneTimePassword::CONTEXTS[:expires_in].'
        elsif context[:max_authenticate_password_count].class != Integer
          raise RuntimeError, 'Mistake OneTimePassword::CONTEXTS[:max_authenticate_password_count].'
        elsif context[:password_length].class != Integer
          raise RuntimeError, 'Mistake OneTimePassword::CONTEXTS[:password_length].'
        elsif context[:password_failed_limit].class != Integer
          raise RuntimeError, 'Mistake OneTimePassword::CONTEXTS[:password_failed_limit].'
        elsif context[:password_failed_period].class != ActiveSupport::Duration
          raise RuntimeError, 'Mistake OneTimePassword::CONTEXTS[:password_failed_period].'
        end
  
        context
      end

      def create_one_time_authentication(context, user_key, user_key_downcase: true)
        if user_key.blank?
          raise OneTimePassword::Errors::NoUserKeyArgmentError,
            'Not present user_key.'
        end

        user_key = user_key.downcase if user_key_downcase

        recent_failed_authenticate_password_count =
          OneTimeAuthentication
            .recent_failed_authenticate_password_count(
              user_key,
              context[:password_failed_period]
            )

        if recent_failed_authenticate_password_count <= context[:password_failed_limit]
          one_time_authentication = OneTimeAuthentication.new(
            function_name: context[:function_name],
            user_key: user_key,
            password_length: context[:password_length],
            expires_seconds: context[:expires_in].to_i,
            max_authenticate_password_count: context[:max_authenticate_password_count],
          )
          one_time_authentication.set_password_and_password_length(context[:password_length])
          one_time_authentication.save!
        else
          one_time_authentication = nil
        end

        one_time_authentication
      end

      def find_one_time_authentication(context, user_key, user_key_downcase: true)
        if user_key.blank?
          raise OneTimePassword::Errors::NoUserKeyArgmentError,
            'Not present user_key.'
        end

        user_key = user_key.downcase if user_key_downcase

        OneTimeAuthentication
          .where(function_name: context[:function_name])
          .where(user_key: user_key)
          .last
      end

      def generate_random_password(length=6)
        length.times.map{ SecureRandom.random_number(10) }.join
      end

      def recent_failed_authenticate_password_count(user_key, time_ago)
        OneTimeAuthentication
          .where(user_key: user_key)
          .recent(time_ago)
          .sum(:failed_count)
      end
    end

    def expired?
      !(self.created_at.to_f <= Time.zone.now.to_f &&
        Time.zone.now.to_f <= self.created_at.to_f + self.expires_seconds.to_f)
    end

    def under_valid_failed_count?
      self.failed_count < self.max_authenticate_password_count
    end

    def authenticate_one_time_client_token!(client_token)
      if (self.client_token.present? &&
        self.client_token == client_token)
        # Refresh client_token, and return this token
        new_client_token = self.set_client_token
        self.save!
        new_client_token
      else
        # Put invalid token(nil) in client_token, and return nil
        self.client_token = nil
        self.save!
        nil
      end
    end

    def authenticate_one_time_password!(password)
      result =
        if !self.expired? && self.under_valid_failed_count?
          !!self.authenticate(password)
        else
          false
        end

      if result
        self.authenticated_at = Time.zone.now
        # Put invalid token(nil) in client_token, and return nil
        self.client_token = nil
      else
        self.failed_count += 1
      end
      self.save!

      result
    end

    def set_client_token
      self.client_token = SecureRandom.urlsafe_base64
    end

    def set_password_and_password_length(length=6)
      self.password = self.password_confirmation = OneTimeAuthentication.generate_random_password(length)
    end
  end
end

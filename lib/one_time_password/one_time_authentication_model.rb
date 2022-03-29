module OneTimePassword
  module OneTimeAuthenticationModel
    extend ActiveSupport::Concern

    included do
      before_create :set_client_token

      has_secure_password
    end

    module ClassMethods
      def find_context(function_name, version)
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
        elsif context[:max_authenticate_password_count].class != Integer
          raise RuntimeError.new('Mistake OneTimePassword::CONTEXTS[:max_authenticate_password_count]')
        elsif context[:password_length].class != Integer
          raise RuntimeError.new('Mistake OneTimePassword::CONTEXTS[:password_length]')
        elsif context[:password_failed_limit].class != Integer
          raise RuntimeError.new('Mistake OneTimePassword::CONTEXTS[:password_failed_limit]')
        elsif context[:password_failed_period].class != ActiveSupport::Duration
          raise RuntimeError.new('Mistake OneTimePassword::CONTEXTS[:password_failed_period]')
        end
  
        context
      end

      def create_one_time_authentication(context, user_key)
        recent_failed_authenticate_password_count =
          OneTimeAuthentication
            .recent_failed_authenticate_password_count(
              user_key,
              context[:password_failed_period]
            )

        if recent_failed_authenticate_password_count <= context[:password_failed_limit]
          one_time_authentication = OneTimeAuthentication.new(
            function_name: context[:function_name],
            version: context[:version],
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

    def set_client_token
      self.client_token = SecureRandom.urlsafe_base64
    end

    def set_password_and_password_length(length=6)
      self.password = self.password_confirmation = OneTimeAuthentication.generate_random_password(length)
    end
  end
end

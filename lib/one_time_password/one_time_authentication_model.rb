module OneTimePassword
  module OneTimeAuthenticationModel
    extend ActiveSupport::Concern

    module ClassMethods
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
    end
  end
end

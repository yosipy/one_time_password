module OneTimePassword
  module Models
    class OneTimeAuthentication < ActiveRecord::Base
      scope :unauthenticated, -> {
        where(authenticated_at: nil)
      }

      scope :recent, -> (time_ago) {
        where(created_at: Time.zone.now.ago(time_ago)...)
      }

      def self.generate_random_password(length=6)
        length.times.map{ SecureRandom.random_number(10) }.join
      end

      def self.recent_failed_authenticate_password_count(user_key, time_ago)
        OneTimeAuthentication
          .where(user_key: user_key)
          .recent(time_ago)
          .sum(:failed_count)
      end

      def set_client_token
        self.client_token = SecureRandom.urlsafe_base64
      end

      def set_password_and_password_length(length=6)
        self.password = self.password_confirmation = OneTimeAuthentication.generate_random_password(length)
      end
    end
  end
end

module OneTimePassword
  module Models
    class OneTimeAuthentication < ActiveRecord::Base
      before_create :set_client_token

      has_secure_password

      scope :unauthenticated, -> {
        where(authenticated_at: nil)
      }

      scope :recent, -> (time_ago) {
        where(created_at: Time.zone.now.ago(time_ago)...)
      }

      scope :tried_authenticate_password, -> {
        where('failed_count >= 1')
      }

      scope :recent_failed_password, -> (time_ago) {
        unauthenticated
          .recent(time_ago)
          .tried_authenticate_password
      }

      def self.generate_random_password(length=6)
        length.times.map{ SecureRandom.random_number(10) }.join
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

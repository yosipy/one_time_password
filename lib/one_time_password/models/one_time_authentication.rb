module OneTimePassword
  module Models
    class OneTimeAuthentication < ActiveRecord::Base
      before_create :set_client_token

      has_secure_password

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

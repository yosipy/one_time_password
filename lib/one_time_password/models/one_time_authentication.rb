module OneTimePassword
  module Models
    class OneTimeAuthentication < ActiveRecord::Base
      scope :unauthenticated, -> {
        where(authenticated_at: nil)
      }

      scope :recent, -> (time_ago) {
        where(created_at: Time.zone.now.ago(time_ago)...)
      }
    end
  end
end

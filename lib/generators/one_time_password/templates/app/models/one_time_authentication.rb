class OneTimeAuthentication < OneTimePassword::Models::OneTimeAuthentication
  enum function_name: OneTimePassword::FUNCTION_NAMES

  scope :unauthenticated, -> {
    where(authenticated_at: nil)
  }

  scope :recent, -> (time_ago) {
    order(created_at: :desc).where(created_at: ..Time.zone.now.ago(time_ago))
  }

  scope :tried_authenticate_password, -> {
    where(count >= 1)
  }
end

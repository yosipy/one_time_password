class OneTimeAuthentication < OneTimePassword::Models::OneTimeAuthentication
  enum function_name: OneTimePassword::FUNCTION_NAMES

  scope :unauthenticated, -> {
    where(authenticated_at: nil)
  }
end

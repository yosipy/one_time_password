class OneTimeAuthentication < OneTimePassword::Models::OneTimeAuthentication
  enum function_name: OneTimePassword::FUNCTION_NAMES
end

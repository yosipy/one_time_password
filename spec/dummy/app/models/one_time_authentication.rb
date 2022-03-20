class OneTimeAuthentication < OneTimePassword::Models::OneTimeAuthentication
  enum function_identifier: OneTimePassword::FUNCTION_IDENTIFIERS
end

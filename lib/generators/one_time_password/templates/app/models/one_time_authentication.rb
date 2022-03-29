class OneTimeAuthentication < ActiveRecord::Base
  enum function_name: OneTimePassword::FUNCTION_NAMES

  include OneTimePassword::OneTimeAuthenticationModel
end

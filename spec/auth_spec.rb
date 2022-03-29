require "rails_helper"

describe 'OneTimePassword::Auth' do
  let(:sign_up_context) do
    {
      function_name: OneTimePassword::FUNCTION_NAMES[:sign_up],
      version: 0,
      expires_in: 30.minutes,
      max_authenticate_password_count: 5,
      password_length: 6,
      password_failed_limit: 10,
      password_failed_period: 1.hour
    }
  end
  let(:sign_in_context) do
    {
      function_name: OneTimePassword::FUNCTION_NAMES[:sign_in],
      version: 0,
      expires_in: 30.minutes,
      max_authenticate_password_count: 5,
      password_length: 10,
      password_failed_limit: 10,
      password_failed_period: 1.hour
    }
  end
  let(:user_key) { 'user@example.com' }

  before do
    OneTimePassword::CONTEXTS = [
      sign_up_context,
      sign_in_context,
    ]
  end
end

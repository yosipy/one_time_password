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

  describe '#authenticate_password' do
    let(:function_name) { OneTimePassword::FUNCTION_NAMES[:sign_in] }
    let(:auth) do
      OneTimePassword::Auth.new(
        function_name,
        0,
        user_key
      )
    end
    let(:failed_count) { 0 }
    let(:beginning_of_validity_period) { Time.new(2022, 1, 1, 12) }
    let!(:one_time_authentication) do
      FactoryBot.create(
        :one_time_authentication,
        function_name: :sign_in,
        user_key: user_key,
        password_length: sign_in_context[:password_length],
        failed_count: failed_count,
        created_at: beginning_of_validity_period
      )
    end

    before do
      auth.find_one_time_authentication
    end

    context 'Argment is correct password' do
      context 'Expired' do
        it 'Return false' do
          travel_to beginning_of_validity_period.since(30.minutes).since(1.second) do
            expect(auth.authenticate_password('0'*10)).to eq(false)
          end
        end
      end

      context 'In validity period' do
        context 'failed_count < max_authenticate_password_count' do
          let(:failed_count) { 4 }
  
          it 'Return true' do
            travel_to beginning_of_validity_period.since(30.minutes).ago(1.minute) do
              expect(auth.authenticate_password('0'*10)).to eq(true)
            end
          end
        end
  
        context 'failed_count == max_authenticate_password_count' do
          let(:failed_count) { 5 }
  
          it 'Return false' do
            travel_to beginning_of_validity_period.since(30.minutes).ago(1.minute) do
              expect(auth.authenticate_password('0'*10)).to eq(false)
            end
          end
        end
  
        context 'failed_count > max_authenticate_password_count' do
          let(:failed_count) { 6 }
  
          it 'Return false' do
            travel_to beginning_of_validity_period.since(30.minutes).ago(1.minute) do
              expect(auth.authenticate_password('0'*10)).to eq(false)
            end
          end
        end
      end
    end

    context 'Argment is incorrect password' do
      context 'Expired' do
        it 'Return false' do
          travel_to beginning_of_validity_period.since(30.minutes).since(1.second) do
            expect(auth.authenticate_password('0'*10)).to eq(false)
          end
        end
      end

      context 'In validity period' do
        it 'Return false' do
          travel_to beginning_of_validity_period.since(30.minutes).ago(1.minute) do
            expect(auth.authenticate_password('9'*10)).to eq(false)
          end
        end
      end
    end
  end
end

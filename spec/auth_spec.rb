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

  describe '#self.find_context' do
    context 'Exist function_name' do
      let(:function_name) { OneTimePassword::FUNCTION_NAMES[:sign_up] }

      context 'Exist version' do
        it 'Return selected context' do
          expect(OneTimePassword::Auth.find_context(function_name, 0))
            .to eq(sign_up_context)
        end
      end

      context 'Not exist version' do
        it 'Raise error' do
          expect{ OneTimePassword::Auth.find_context(function_name, 1) }
            .to raise_error(ArgumentError, 'Not found context.')
        end
      end
    end

    context 'Not exist function_name' do
      let(:function_name) { OneTimePassword::FUNCTION_NAMES[:change_email] }

      context 'exist version' do
        it 'Raise error' do
          expect{ OneTimePassword::Auth.find_context(function_name, 0) }
            .to raise_error(ArgumentError, 'Not found context.')
        end
      end

      context 'Not exist version' do
        it 'Raise error' do
          expect{ OneTimePassword::Auth.find_context(function_name, 1) }
           .to raise_error(ArgumentError, 'Not found context.')
        end
      end
    end
  end

  describe '#create_one_time_authentication' do
    let!(:now) { Time.parse('2022-3-26 12:00') }
    let(:function_name) { OneTimePassword::FUNCTION_NAMES[:sign_in] }

    let(:auth) do
      OneTimePassword::Auth.new(
        function_name,
        0,
        user_key
      )
    end

    context 'recent_failed_authenticate_password_count <= 10 from 1 hour ago' do
      let!(:failed_one_time_authentications) {
        10.times.map do |index|
          FactoryBot.create(
            :one_time_authentication,
            function_name: :sign_up,
            user_key: user_key,
            authenticated_at: nil,
            created_at: now.ago(sign_in_context[:password_failed_period]),
            failed_count: 1
          )
        end
      }

      it 'Created one_time_authentication' do
        travel_to now do
          expect{
            auth.create_one_time_authentication
          }.to change{ OneTimeAuthentication.count }.by(1)
        end
      end

      it 'Return created one_time_authentication' do
        travel_to now do
          result = auth.create_one_time_authentication
          expect(result.id).to eq(OneTimeAuthentication.last.id)
        end
      end

      it 'Has @one_time_authentication from context(has raw password)' do
        aggregate_failures do
          travel_to now do
            # mock: To fixed password
            allow(SecureRandom).to receive(:random_number).and_return(0)
            # mock: To fixed client_token
            allow(SecureRandom).to receive(:urlsafe_base64).and_return('XXXXXXXXXXXXXXX')

            auth.create_one_time_authentication
            one_time_authentication = auth.instance_variable_get(:@one_time_authentication)
            expect(one_time_authentication.function_name).to eq('sign_in')
            expect(one_time_authentication.version).to eq(0)
            expect(one_time_authentication.user_key).to eq(user_key)
            expect(one_time_authentication.password_length).to eq(sign_in_context[:password_length])
            expect(one_time_authentication.expires_seconds).to eq(sign_in_context[:expires_in].to_i)
            expect(one_time_authentication.max_authenticate_password_count).to eq(sign_in_context[:max_authenticate_password_count])
            expect(one_time_authentication.client_token).to eq('XXXXXXXXXXXXXXX')
            expect(one_time_authentication.password).to eq('0'*10)
            expect(one_time_authentication.password_confirmation).to eq('0'*10)
          end
        end
      end
    end

    context "Other user's recent_failed_authenticate_password_count > 10 from 1 hour ago" do
      let(:other_user_key) { 'other_user@example.com' }
      let!(:failed_one_time_authentications) {
        11.times.map do |index|
          FactoryBot.create(
            :one_time_authentication,
            function_name: :sign_up,
            user_key: other_user_key,
            authenticated_at: nil,
            created_at: now.ago(sign_in_context[:password_failed_period]),
            failed_count: 1
          )
        end
      }

      it 'Created one_time_authentication' do
        travel_to now do
          expect{
            auth.create_one_time_authentication
          }.to change{ OneTimeAuthentication.count }.by(1)
        end
      end

      it 'Return created one_time_authentication' do
        travel_to now do
          result = auth.create_one_time_authentication
          expect(result.id).to eq(OneTimeAuthentication.last.id)
        end
      end
    end

    context 'recent_failed_authenticate_password_count > 10 from 1 hour ago' do
      let!(:failed_one_time_authentications) {
        11.times.map do |index|
          FactoryBot.create(
            :one_time_authentication,
            function_name: :sign_up,
            user_key: user_key,
            authenticated_at: nil,
            created_at: now.ago(sign_in_context[:password_failed_period]),
            failed_count: 1
          )
        end
      }

      it 'Not created one_time_authentication' do
        travel_to now do
          expect{
            auth.create_one_time_authentication
          }.to change{ OneTimeAuthentication.count }.by(0)
        end
      end

      it 'Return nil' do
        travel_to now do
          result = auth.create_one_time_authentication
          expect(result).to eq(nil)
        end
      end
    end
  end

  describe '#find_one_time_authentication' do
    let(:function_name) { OneTimePassword::FUNCTION_NAMES[:sign_in] }
    let(:auth) do
      OneTimePassword::Auth.new(
        function_name,
        0,
        user_key
      )
    end

    context 'There is a match function_name, version and user_key in the table' do
      let!(:one_time_authentications) do
        3.times.map do |num|
          FactoryBot.create(
            :one_time_authentication,
            function_name: :sign_in,
            user_key: user_key
          )
        end
      end
  
      it 'Return last one_time_authentication in match function_name, version and user_key' do
        expect(auth.find_one_time_authentication.id).to eq(one_time_authentications.last.id)
      end

      it 'Has @one_time_authentication in match function_name, version and user_key' do
        auth.find_one_time_authentication
        one_time_authentication = auth.instance_variable_get(:@one_time_authentication)
        expect(one_time_authentication.id).to eq(one_time_authentications.last.id)
      end

      it 'Password and password_confirmation is nil, because hashing password in password_digest' do
        one_time_authentication = auth.find_one_time_authentication
        aggregate_failures do
          expect(one_time_authentication.password).to eq(nil)
          expect(one_time_authentication.password_confirmation).to eq(nil)
        end
      end
    end

    context 'There is not a match function_name in the table' do
      let!(:one_time_authentications) do
        3.times.map do |num|
          FactoryBot.create(
            :one_time_authentication,
            function_name: :sign_up,
            user_key: user_key
          )
        end
      end
  
      it 'Return nil' do
        expect(auth.find_one_time_authentication).to eq(nil)
      end

      it 'Has @one_time_authentication is nil' do
        auth.find_one_time_authentication
        one_time_authentication = auth.instance_variable_get(:@one_time_authentication)
        expect(one_time_authentication).to eq(nil)
      end
    end

    context 'There is not a match version in the table' do
      let!(:one_time_authentications) do
        3.times.map do |num|
          FactoryBot.create(
            :one_time_authentication,
            function_name: :sign_in,
            version: 1,
            user_key: user_key
          )
        end
      end
  
      it 'Return nil' do
        expect(auth.find_one_time_authentication).to eq(nil)
      end

      it 'Has @one_time_authentication is nil' do
        auth.find_one_time_authentication
        one_time_authentication = auth.instance_variable_get(:@one_time_authentication)
        expect(one_time_authentication).to eq(nil)
      end
    end

    context 'There is not a match version in the table' do
      let!(:one_time_authentications) do
        3.times.map do |num|
          FactoryBot.create(
            :one_time_authentication,
            function_name: :sign_in,
            user_key: 'other_user@example.com'
          )
        end
      end
  
      it 'Return nil' do
        expect(auth.find_one_time_authentication).to eq(nil)
      end

      it 'Has @one_time_authentication is nil' do
        auth.find_one_time_authentication
        one_time_authentication = auth.instance_variable_get(:@one_time_authentication)
        expect(one_time_authentication).to eq(nil)
      end
    end
  end

  describe '#expired?' do
    let(:function_name) { OneTimePassword::FUNCTION_NAMES[:sign_in] }
    let(:auth) do
      OneTimePassword::Auth.new(
        function_name,
        0,
        user_key
      )
    end

    let(:beginning_of_validity_period) { Time.new(2022, 1, 1, 12) }
    let!(:one_time_authentication) do
      FactoryBot.create(
        :one_time_authentication,
        function_name: :sign_in,
        user_key: user_key,
        created_at: beginning_of_validity_period
      )
    end

    context 'Time.now is before beginning of validity period' do
      it 'Return true' do
        travel_to beginning_of_validity_period.ago(1.minute) do
          auth.find_one_time_authentication
          expect(auth.expired?).to eq(true)
        end
      end
    end

    context 'Time.now is after beginning of validity period' do
      it 'Return false' do
        travel_to beginning_of_validity_period do
          auth.find_one_time_authentication
          expect(auth.expired?).to eq(false)
        end
      end
    end

    context 'Time.now is before end of validity period' do
      it 'Return false' do
        travel_to beginning_of_validity_period.since(30.minutes).ago(1.minute) do
          auth.find_one_time_authentication
          expect(auth.expired?).to eq(false)
        end
      end
    end

    context 'Time.now is before end of validity period' do
      it 'Return true' do
        travel_to beginning_of_validity_period.since(30.minutes).since(1.second) do
          auth.find_one_time_authentication
          expect(auth.expired?).to eq(true)
        end
      end
    end
  end

  describe '#under_valid_failed_count?' do
    let(:function_name) { OneTimePassword::FUNCTION_NAMES[:sign_in] }
    let(:auth) do
      OneTimePassword::Auth.new(
        function_name,
        0,
        user_key
      )
    end
    let!(:one_time_authentication) do
      FactoryBot.create(
        :one_time_authentication,
        function_name: :sign_in,
        user_key: user_key,
        failed_count: failed_count
      )
    end

    context 'failed_count < max_authenticate_password_count' do
      let(:failed_count) { 4 }

      it 'Return true' do
        auth.find_one_time_authentication
        expect(auth.under_valid_failed_count?).to eq(true)
      end
    end

    context 'failed_count == max_authenticate_password_count' do
      let(:failed_count) { 5 }

      it 'Return true' do
        auth.find_one_time_authentication
        expect(auth.under_valid_failed_count?).to eq(false)
      end
    end

    context 'failed_count > max_authenticate_password_count' do
      let(:failed_count) { 6 }

      it 'Return true' do
        auth.find_one_time_authentication
        expect(auth.under_valid_failed_count?).to eq(false)
      end
    end
  end

  describe '#authenticate_client_token' do
    let(:function_name) { OneTimePassword::FUNCTION_NAMES[:sign_in] }
    let(:auth) do
      OneTimePassword::Auth.new(
        function_name,
        0,
        user_key
      )
    end
    let!(:one_time_authentication) do
      # First client_token
      allow(SecureRandom).to receive(:urlsafe_base64).and_return('XXXXXXXXXXXXXXX')
      FactoryBot.create(
        :one_time_authentication,
        function_name: :sign_in,
        user_key: user_key
      )
    end

    before do
      # mock: for second client_token
      allow(SecureRandom).to receive(:urlsafe_base64).and_return('YYYYYYYYYYYYYYY')

      auth.find_one_time_authentication
    end

    context 'Argment is correct client_token' do
      it 'Return regenerate client_token, and update client_token' do
        aggregate_failures do
          expect(auth.authenticate_client_token('XXXXXXXXXXXXXXX')).to eq('YYYYYYYYYYYYYYY')
          expect(one_time_authentication.reload.client_token).to eq('YYYYYYYYYYYYYYY')
        end
      end
    end

    context 'Argment is incorrect client_token' do
      it 'Return nil, and client_token is nil' do
        aggregate_failures do
          expect(auth.authenticate_client_token('ZZZZZZZZZZZZZZZ')).to eq(nil)
          expect(one_time_authentication.reload.client_token).to eq(nil)
        end
      end
    end

    context 'Argment is nil, and one_time_authentication.client_token is nil' do
      before do
        one_time_authentication.update(client_token: nil)
      end
      it 'Return nil, and client_token is nil' do
        aggregate_failures do
          expect(auth.authenticate_client_token(nil)).to eq(nil)
          expect(one_time_authentication.reload.client_token).to eq(nil)
        end
      end
    end

    context 'Argment is empty, and one_time_authentication.client_token is empty' do
      before do
        one_time_authentication.update(client_token: '')
      end

      it 'Return nil, and client_token is nil' do
        aggregate_failures do
          expect(auth.authenticate_client_token('')).to eq(nil)
          expect(one_time_authentication.reload.client_token).to eq(nil)
        end
      end
    end
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

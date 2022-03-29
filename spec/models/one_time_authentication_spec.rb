require "rails_helper"

describe 'OneTimeAuthentication' do
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

  describe '#unauthenticated' do
    let!(:authenticated_one_time_authentication) {
      FactoryBot.create(
        :one_time_authentication,
        function_name: :sign_up,
        authenticated_at: Time.zone.now
      )
    }
    let!(:unauthenticated_one_time_authentication) {
      FactoryBot.create(
        :one_time_authentication,
        function_name: :sign_up
      )
    }

    it 'Return one_time_authentication that authenticated_at is not nil' do
      expect(
        OneTimeAuthentication.unauthenticated.pluck(:id)
      ).to eq([unauthenticated_one_time_authentication.id])
    end
  end

  describe '#recent' do
    let!(:now) { Time.parse('2022-3-26 12:00') }
    let!(:time_ago) { 3.hours }
    let!(:out_range) {
      travel_to now.ago(time_ago).ago(1.second) do
        FactoryBot.create(
          :one_time_authentication,
          function_name: :sign_up
        )
      end
    }
    let!(:in_range) {
      travel_to now.ago(time_ago) do
        FactoryBot.create(
          :one_time_authentication,
          function_name: :sign_up
        )
      end
    }

    it 'Return one_time_authentication in_range' do
      travel_to now do
        expect(
          OneTimeAuthentication.recent(time_ago).pluck(:id)
        ).to eq([in_range.id])
      end
    end
  end

  describe '#self.generate_random_password' do
    context 'Argument is nil' do
      it 'Generate string of numbers of length 6' do
        aggregate_failures do
          expect(OneTimeAuthentication.generate_random_password).to match(/^[0-9]{6}$/)

          # mock
          allow(SecureRandom).to receive(:random_number).and_return(0)
          expect(OneTimeAuthentication.generate_random_password).to eq('0'*6)
        end
      end
    end

    context 'Argument is any length' do
      let(:length) { 10 }

      it 'Generate string of numbers of any length' do
        aggregate_failures do
          expect(OneTimeAuthentication.generate_random_password(length)).to match(/^[0-9]{#{length}}$/)

          # mock
          allow(SecureRandom).to receive(:random_number).and_return(0)
          expect(OneTimeAuthentication.generate_random_password(length)).to eq('0'*length)
        end
      end
    end
  end

  describe '#recent_failed_authenticate_password_count' do
    let!(:now) { Time.parse('2022-3-26 12:00') }
    let!(:time_ago) { 3.hours }

    context "Exist same user's one_time_authentications" do
      context 'In time' do
        let!(:one_time_authentications) {
          [
            {
              authenticated_at: nil,
              created_at: now.ago(time_ago),
              failed_count: 1
            },
            {
              authenticated_at: now.ago(1.hour),
              created_at: now,
              failed_count: 10
            },
          ].map do |params|
            FactoryBot.create(
              :one_time_authentication,
              function_name: :sign_up,
              user_key: user_key,
              authenticated_at: params[:authenticated_at],
              created_at: params[:created_at],
              failed_count: params[:failed_count]
            )
          end
        }
  
        it 'Return sum failed_count in time' do
          travel_to now do
            expect(
              OneTimeAuthentication
                .recent_failed_authenticate_password_count(user_key, time_ago)
            ).to eq(11)
          end
        end
      end

      context 'Out time' do
        let!(:one_time_authentication) {
          FactoryBot.create(
            :one_time_authentication,
            function_name: :sign_up,
            user_key: user_key,
            authenticated_at: nil,
            created_at: now.ago(time_ago).ago(1.second),
            failed_count: 1
          )
        }
  
        it 'Return 0' do
          travel_to now do
            expect(
              OneTimeAuthentication
                .recent_failed_authenticate_password_count(user_key, time_ago)
            ).to eq(0)
          end
        end
      end
    end

    context "Not exist same user's one_time_authentications" do
      let(:other_user_key) { 'other_user@example.com' }
      let!(:one_time_authentication) {
        FactoryBot.create(
          :one_time_authentication,
          function_name: :sign_up,
          user_key: other_user_key,
          authenticated_at: nil,
          created_at: now.ago(time_ago),
          failed_count: 1
        )
      }

      it 'Return 0' do
        travel_to now do
          expect(
            OneTimeAuthentication
              .recent_failed_authenticate_password_count(user_key, time_ago)
          ).to eq(0)
        end
      end
    end
  end

  describe '#self.find_context' do
    context 'Exist function_name' do
      let(:function_name) { OneTimePassword::FUNCTION_NAMES[:sign_up] }

      context 'Exist version' do
        it 'Return selected context' do
          expect(OneTimeAuthentication.find_context(function_name, 0))
            .to eq(sign_up_context)
        end
      end

      context 'Not exist version' do
        it 'Raise error' do
          expect{ OneTimeAuthentication.find_context(function_name, 1) }
            .to raise_error(ArgumentError, 'Not found context.')
        end
      end
    end

    context 'Not exist function_name' do
      let(:function_name) { OneTimePassword::FUNCTION_NAMES[:change_email] }

      context 'exist version' do
        it 'Raise error' do
          expect{ OneTimeAuthentication.find_context(function_name, 0) }
            .to raise_error(ArgumentError, 'Not found context.')
        end
      end

      context 'Not exist version' do
        it 'Raise error' do
          expect{ OneTimeAuthentication.find_context(function_name, 1) }
           .to raise_error(ArgumentError, 'Not found context.')
        end
      end
    end
  end

  describe '#self.create_one_time_authentication' do
    let!(:now) { Time.parse('2022-3-26 12:00') }
    let(:function_name) { OneTimePassword::FUNCTION_NAMES[:sign_in] }

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
            OneTimeAuthentication.create_one_time_authentication(
              sign_in_context,
              user_key
            )
          }.to change{ OneTimeAuthentication.count }.by(1)
        end
      end

      it 'Return created one_time_authentication' do
        travel_to now do
          result = OneTimeAuthentication.create_one_time_authentication(
            sign_in_context,
            user_key
          )
          expect(result.id).to eq(OneTimeAuthentication.last.id)
        end
      end

      it 'Has one_time_authentication from context(has raw password)' do
        aggregate_failures do
          travel_to now do
            # mock: To fixed password
            allow(SecureRandom).to receive(:random_number).and_return(0)
            # mock: To fixed client_token
            allow(SecureRandom).to receive(:urlsafe_base64).and_return('XXXXXXXXXXXXXXX')

            one_time_authentication = OneTimeAuthentication.create_one_time_authentication(
              sign_in_context,
              user_key
            )
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
            OneTimeAuthentication.create_one_time_authentication(
              sign_in_context,
              user_key
            )
          }.to change{ OneTimeAuthentication.count }.by(1)
        end
      end

      it 'Return created one_time_authentication' do
        travel_to now do
          result = OneTimeAuthentication.create_one_time_authentication(
            sign_in_context,
            user_key
          )
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
            OneTimeAuthentication.create_one_time_authentication(
              sign_in_context,
              user_key
            )
          }.to change{ OneTimeAuthentication.count }.by(0)
        end
      end

      it 'Return nil' do
        travel_to now do
          result = OneTimeAuthentication.create_one_time_authentication(
            sign_in_context,
            user_key
          )
          expect(result).to eq(nil)
        end
      end
    end
  end

  describe '#self.find_one_time_authentication' do
    let(:function_name) { OneTimePassword::FUNCTION_NAMES[:sign_in] }

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
        expect(
          OneTimeAuthentication.find_one_time_authentication(sign_in_context, user_key).id
        ).to eq(one_time_authentications.last.id)
      end

      it 'Password and password_confirmation is nil, because hashing password in password_digest' do
        one_time_authentication = OneTimeAuthentication.find_one_time_authentication(sign_in_context, user_key)
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
        expect(
          OneTimeAuthentication.find_one_time_authentication(sign_in_context, user_key)
        ).to eq(nil)
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
        expect(
          OneTimeAuthentication.find_one_time_authentication(sign_in_context, user_key)
        ).to eq(nil)
      end
    end

    context 'There is not a match user_key in the table' do
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
        expect(
          OneTimeAuthentication.find_one_time_authentication(sign_in_context, user_key)
        ).to eq(nil)
      end
    end
  end

  describe '#expired?' do
    let(:function_name) { OneTimePassword::FUNCTION_NAMES[:sign_in] }

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
          expect(one_time_authentication.expired?).to eq(true)
        end
      end
    end

    context 'Time.now is after beginning of validity period' do
      it 'Return false' do
        travel_to beginning_of_validity_period do
          expect(one_time_authentication.expired?).to eq(false)
        end
      end
    end

    context 'Time.now is before end of validity period' do
      it 'Return false' do
        travel_to beginning_of_validity_period.since(30.minutes).ago(1.minute) do
          expect(one_time_authentication.expired?).to eq(false)
        end
      end
    end

    context 'Time.now is before end of validity period' do
      it 'Return true' do
        travel_to beginning_of_validity_period.since(30.minutes).since(1.second) do
          expect(one_time_authentication.expired?).to eq(true)
        end
      end
    end
  end

  describe '#under_valid_failed_count?' do
    let(:function_name) { OneTimePassword::FUNCTION_NAMES[:sign_in] }
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
        expect(
          one_time_authentication.under_valid_failed_count?
        ).to eq(true)
      end
    end

    context 'failed_count == max_authenticate_password_count' do
      let(:failed_count) { 5 }

      it 'Return true' do
        expect(
          one_time_authentication.under_valid_failed_count?
        ).to eq(false)
      end
    end

    context 'failed_count > max_authenticate_password_count' do
      let(:failed_count) { 6 }

      it 'Return true' do
        expect(
          one_time_authentication.under_valid_failed_count?
        ).to eq(false)
      end
    end
  end

  describe '#authenticate_client_token' do
    let(:function_name) { OneTimePassword::FUNCTION_NAMES[:sign_in] }
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
    end

    context 'Argment is correct client_token' do
      it 'Return regenerate client_token, and update client_token' do
        aggregate_failures do
          expect(
            one_time_authentication.authenticate_one_time_client_token('XXXXXXXXXXXXXXX')
          ).to eq('YYYYYYYYYYYYYYY')
          expect(one_time_authentication.reload.client_token).to eq('YYYYYYYYYYYYYYY')
        end
      end
    end

    context 'Argment is incorrect client_token' do
      it 'Return nil, and client_token is nil' do
        aggregate_failures do
          expect(
            one_time_authentication.authenticate_one_time_client_token('ZZZZZZZZZZZZZZZ')
          ).to eq(nil)
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
          expect(
            one_time_authentication.authenticate_one_time_client_token(nil)
        ).to eq(nil)
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
          expect(
            one_time_authentication.authenticate_one_time_client_token('')
          ).to eq(nil)
          expect(one_time_authentication.reload.client_token).to eq(nil)
        end
      end
    end
  end

  describe '#authenticate_password' do
    let(:function_name) { OneTimePassword::FUNCTION_NAMES[:sign_in] }
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

    context 'Argment is correct password' do
      context 'Expired' do
        it 'Return false' do
          travel_to beginning_of_validity_period.since(30.minutes).since(1.second) do
            expect(
              one_time_authentication.authenticate_one_time_password('0'*10)
            ).to eq(false)
          end
        end
      end

      context 'In validity period' do
        context 'failed_count < max_authenticate_password_count' do
          let(:failed_count) { 4 }
  
          it 'Return true' do
            travel_to beginning_of_validity_period.since(30.minutes).ago(1.minute) do
              expect(
                one_time_authentication.authenticate_one_time_password('0'*10)
              ).to eq(true)
            end
          end
        end
  
        context 'failed_count == max_authenticate_password_count' do
          let(:failed_count) { 5 }
  
          it 'Return false' do
            travel_to beginning_of_validity_period.since(30.minutes).ago(1.minute) do
              expect(
                one_time_authentication.authenticate_one_time_password('0'*10)
              ).to eq(false)
            end
          end
        end
  
        context 'failed_count > max_authenticate_password_count' do
          let(:failed_count) { 6 }
  
          it 'Return false' do
            travel_to beginning_of_validity_period.since(30.minutes).ago(1.minute) do
              expect(
                one_time_authentication.authenticate_one_time_password('0'*10)
              ).to eq(false)
            end
          end
        end
      end
    end

    context 'Argment is incorrect password' do
      context 'Expired' do
        it 'Return false' do
          travel_to beginning_of_validity_period.since(30.minutes).since(1.second) do
            expect(
              one_time_authentication.authenticate_one_time_password('0'*10)
            ).to eq(false)
          end
        end
      end

      context 'In validity period' do
        it 'Return false' do
          travel_to beginning_of_validity_period.since(30.minutes).ago(1.minute) do
            expect(
              one_time_authentication.authenticate_one_time_password('9'*10)
            ).to eq(false)
          end
        end
      end
    end
  end

  describe '#set_client_token' do
    let(:one_time_authentication) { OneTimeAuthentication.new }

    it 'Generate token and set to self.client_token' do
      # mock
      allow(SecureRandom).to receive(:urlsafe_base64).and_return('XXXXXXXXXXXXXXX')
      expect{ one_time_authentication.set_client_token }
        .to change{ one_time_authentication.client_token }
        .from(nil)
        .to('XXXXXXXXXXXXXXX')
    end
  end

  describe '#set_password_and_password_length' do
    subject do
      expect{ one_time_authentication.set_password_and_password_length(length) }
        .to change{ one_time_authentication.password }
        .from(nil)
        .to('0'*length)
        .and change{ one_time_authentication.password_confirmation }
        .from(nil)
        .to('0'*length)
    end

    let(:one_time_authentication) { OneTimeAuthentication.new }

    before do
      # mock
      allow(SecureRandom).to receive(:random_number).and_return(0)
    end

    context 'Argument is nil' do
      let(:length) { 6 }

      it 'Set password of numbers of length 6' do
        subject
      end
    end

    context 'argument is any length' do
      let(:length) { 10 }

      it 'Set password of numbers of any length' do
        subject
      end
    end
  end
end

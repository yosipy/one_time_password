require 'rails_helper'

RSpec.describe "TestUsers", type: :request do
  let(:email) { 'user@example.com' }
  let(:password) { 'password' }

  describe 'POST /test_user/sign_up_one_time_auth' do
    subject do
      post '/test_user/sign_up_one_time_auth', params: { email: email }
    end

    let(:one_time_password) { '0'*6 }

    before do
      # mock: To fixed password
      allow(SecureRandom).to receive(:random_number).and_return(0)
  
      # mock: To fixed client_token
      allow(SecureRandom).to receive(:urlsafe_base64).and_return('XXXXXXXXXXXXXXX')
    end

    it '200' do
      subject
      expect(response).to have_http_status(200)
    end

    it 'Return one time client_token' do
      subject
      expect(JSON.parse(response.body)['client_token']).to eq('XXXXXXXXXXXXXXX')
    end

    it 'Send mail with one time password' do
      aggregate_failures do
        expect {
          subject
        }.to change {
          ActionMailer::Base.deliveries.count
        }.by(1)
        expect(ActionMailer::Base.deliveries.last.to.first).to eq(email)
        expect(ActionMailer::Base.deliveries.last.subject).to eq(one_time_password)
      end
    end
  end

  describe 'POST /test_user/sign_up' do
    subject do
      post '/test_user/sign_up', params: {
        client_token: @client_token,
        one_time_password: @one_time_password,
        email: email,
        user_password: password
      }
    end

    before do
      post '/test_user/sign_up_one_time_auth', params: { email: email }
      @client_token = JSON.parse(response.body)['client_token']
      @one_time_password = ActionMailer::Base.deliveries.last.subject
    end

    context 'Correct one time password at 1 times' do
      it '200' do
        subject
        expect(response).to have_http_status(200)
      end

      it 'Created TestUser' do
        aggregate_failures do
          expect {
            subject
          }.to change {
            TestUser.count
          }.by(1)
          expect(TestUser.last.email).to eq(email)
        end
      end
    end

    context 'Mistaken one time password at 4 times' do
      before do
        @one_time_password += '0' # mistaken one time password
        3.times.each do |index|
          post '/test_user/sign_up', params: {
            client_token: @client_token,
            one_time_password: @one_time_password,
            email: email,
            user_password: password
          }

          @client_token = JSON.parse(response.body)['client_token']
        end
      end

      it '401' do
        subject
        expect(response).to have_http_status(401)
      end

      it 'Not create test_user' do
        expect {
          subject
        }.to change {
          TestUser.count
        }.by(0)
      end

      it 'Multiply failed_count' do
        subject
        expect(OneTimeAuthentication.last.failed_count).to eq(4)
      end

      it 'Return client_token' do
        subject
        expect(JSON.parse(response.body)['client_token']).not_to be_nil
      end
    end

    context 'Correct one time password at 5 times' do
      before do
        failed_one_time_password = @one_time_password + '0'
        4.times.each do |index|
          post '/test_user/sign_up', params: {
            client_token: @client_token,
            one_time_password: failed_one_time_password,
            email: email,
            user_password: password
          }

          @client_token = JSON.parse(response.body)['client_token']
        end
      end

      it '200' do
        subject
        expect(response).to have_http_status(200)
      end

      it 'Create test_user' do
        aggregate_failures do
          expect {
            subject
          }.to change {
            TestUser.count
          }.by(1)
          expect(TestUser.last.email).to eq(email)
        end
      end

      it 'Not multiply failed_count' do
        expect {
          subject
        }.to change {
          OneTimeAuthentication.last.failed_count
        }.by(0)
      end

      it 'client_token is nil' do
        subject
        expect(OneTimeAuthentication.last.reload.client_token).to be_nil
      end
    end

    context 'Mistaken one time password at 5 times' do
      before do
        @one_time_password += '0' # mistaken one time password
        4.times.each do |index|
          post '/test_user/sign_up', params: {
            client_token: @client_token,
            one_time_password: @one_time_password,
            email: email,
            user_password: password
          }

          @client_token = JSON.parse(response.body)['client_token']
        end
      end

      it '401' do
        subject
        expect(response).to have_http_status(401)
      end

      it 'Not create test_user' do
        aggregate_failures do
          expect {
            subject
          }.to change {
            TestUser.count
          }.by(0)
        end
      end

      it 'Multiply failed_count' do
        expect {
          subject
        }.to change {
          OneTimeAuthentication.last.failed_count
        }.by(1)
      end
    end
  end
end

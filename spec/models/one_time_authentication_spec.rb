require "rails_helper"

describe 'OneTimeAuthentication' do
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

    context 'argument is any length' do
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

  describe '#tried_authenticate_password' do
    let!(:inputed_password_one_time_authentications) {
      [1, 5].map do |count|
        FactoryBot.create(
          :one_time_authentication,
          function_name: :sign_up,
          count: count
        )
      end
    }
    let!(:uninputed_password_one_time_authentication) {
      FactoryBot.create(
        :one_time_authentication,
        function_name: :sign_up,
        count: 0
      )
    }

    it 'Return one_time_authentication that count >= 1' do
      expect(
        OneTimeAuthentication
          .tried_authenticate_password
          .pluck(:id)
      ).to eq([
        inputed_password_one_time_authentications[0].id,
        inputed_password_one_time_authentications[1].id,
      ])
    end
  end

  describe '#recent_failed_password' do
    let!(:now) { Time.parse('2022-3-26 12:00') }
    let!(:time_ago) { 3.hours }
    let!(:unscope) {
      [
        {
          authenticated_at: nil,
          created_at: now.ago(time_ago).ago(10000.second),
          count: 1
        },
        {
          authenticated_at: now.ago(1.hour),
          created_at: now.ago(time_ago),
          count: 1
        },
        {
          authenticated_at: nil,
          created_at: now.ago(time_ago),
          count: 0
        },
      ].map do |params|
        FactoryBot.create(
          :one_time_authentication,
          function_name: :sign_up,
          authenticated_at: params[:authenticated_at],
          created_at: params[:created_at],
          count: params[:count]
        )
      end
    }
    let!(:scope) {
      [
        {
          authenticated_at: nil,
          created_at: now.ago(time_ago),
          count: 1
        },
        {
          authenticated_at: nil,
          created_at: now,
          count: 5
        },
      ].map do |params|
        FactoryBot.create(
          :one_time_authentication,
          function_name: :sign_up,
          authenticated_at: params[:authenticated_at],
          created_at: params[:created_at],
          count: params[:count]
        )
      end
    }

    it 'Return input failed password one_time_authentications' do
      travel_to now do
        expect(
          OneTimeAuthentication
            .recent_failed_password(time_ago)
            .pluck(:id)
        ).to eq(scope.pluck(:id))
      end
    end
  end
end

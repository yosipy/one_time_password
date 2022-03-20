require "rails_helper"

describe 'OneTimeAuthentication' do
  describe '#self.generate_random_password' do
    context 'argument is nil' do
      it 'generate string of numbers of length 6' do
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

      it 'generate string of numbers of any length' do
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

    it 'generate token and set to self.client_token' do
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

    context 'argument is nil' do
      let(:length) { 6 }

      it 'set password of numbers of length 6' do
        subject
      end
    end

    context 'argument is any length' do
      let(:length) { 10 }

      it 'set password of numbers of any length' do
        subject
      end
    end
  end
end

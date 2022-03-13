require "rails_helper"

describe 'OneTimePassword' do
  it 'it has a version number' do
    expect(OneTimePassword::VERSION).to be_truthy
  end
end

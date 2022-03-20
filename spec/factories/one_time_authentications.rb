FactoryBot.define do
  factory :one_time_authentication do
    function_identifier { nil }
    version { 0 }
    sequence(:user_key) { |n|
      "user#{n}@example.com"
    }
    password_length { 6 }
    password { '0'*password_length }
    expires_seconds { 30.minutes.to_i }
    count { 0 }
    max_count { 5 }
  end
end

FactoryBot.define do
  factory :one_time_authentication do
    function_name { nil }
    sequence(:user_key) { |n|
      "user#{n}@example.com"
    }
    password_length { 6 }
    password { '0'*password_length }
    expires_seconds { 30.minutes.to_i }
    failed_count { 0 }
    max_authenticate_password_count { 5 }
  end
end

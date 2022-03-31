Rails.application.routes.draw do
  post 'test_user/sign_up_one_time_auth', to: 'test_users#create_one_time_auth'
  post 'test_user/sign_up', to: 'test_users#create'
end

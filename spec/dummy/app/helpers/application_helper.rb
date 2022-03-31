module ApplicationHelper
  def sign_up(email, password)
    TestUser.create(email: email, password: password)
  end
end

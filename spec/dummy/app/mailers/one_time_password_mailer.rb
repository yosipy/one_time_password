class OneTimePasswordMailer < ApplicationMailer
  def send_one_time_password(email, one_time_password)
    mail to: email, subject: one_time_password
  end
end

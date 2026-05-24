class UserMailer < ApplicationMailer
  def password_reset(user, token)
    @user       = user
    @reset_link = "#{ENV.fetch('FRONTEND_URL', 'http://localhost:5173')}/auth/reset-password?token=#{token}"
    mail(to: user.email, subject: "Password Reset Request")
  end

  def group_invite(email, group, token)
    @group       = group
    @invite_link = "#{ENV.fetch('FRONTEND_URL', 'http://localhost:5173')}/join?token=#{token}"
    mail(to: email, subject: "You've been invited to join #{group.name}")
  end
end

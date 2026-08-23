class UserMailer < ApplicationMailer
  def password_reset(user, token)
    @user       = user
    @reset_link = "#{ENV.fetch('FRONTEND_URL', 'http://localhost:5173')}/auth/reset-password?token=#{token}"
    mail(to: user.email, subject: "Password Reset Request")
  end

  def group_invite(email, group, token, inviter)
    @group       = group
    @inviter     = inviter
    @invite_link = "#{ENV.fetch('APP_URL', 'http://localhost:8080')}/invites/#{token}"
    mail(to: email, subject: "#{inviter.display_name} invited you to join #{group.name} on Square")
  end
end

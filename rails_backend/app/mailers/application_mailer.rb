class ApplicationMailer < ActionMailer::Base
  default from: "Square <from@example.com>"
  layout "mailer"

  before_action :attach_logo

  private

  # Inline (CID) attachment so the brand mark in the layout renders as a real
  # image instead of a CSS box — some email clients strip or ignore the
  # layout's <style> block, which broke the div-based "S" mark.
  def attach_logo
    attachments.inline["square_logo.png"] =
      File.read(Rails.root.join("app/assets/images/square_logo.png"))
  end
end

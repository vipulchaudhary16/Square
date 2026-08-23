# Server-rendered — this is opened directly in a browser from an invite
# email/link, not called by the Flutter app or any JSON client. Deliberately
# not an ApplicationController subclass: it needs no bearer token (there's
# none to have, since the visitor hasn't necessarily opened the app at all)
# and no JSON rendering.
class InvitesController < ActionController::Base
  layout "invite"
  skip_forgery_protection

  before_action :load_invite

  def show
    @state = compute_state
  end

  def accept
    @state = compute_state
    return render :show unless @state == :ready

    if @invite.accept_for_web!(params[:password])
      @state = :success
    else
      @error = "Incorrect password. Try again."
    end
    render :show
  end

  private

  def load_invite
    @invite = GroupInvite.find_by(token: params[:token])
  end

  def compute_state
    return :not_found unless @invite
    return :revoked if @invite.status == "revoked"
    return :accepted if @invite.status == "accepted"
    return :expired if @invite.expired?
    return :no_account unless @invite.invited_user

    :ready
  end
end

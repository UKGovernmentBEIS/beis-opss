class ResponsiblePersons::TeamMembersController < ApplicationController
  before_action :set_responsible_person
  before_action :authorize_responsible_person, only: %i[new create]
  before_action :set_team_member, only: %i[new create]
  skip_before_action :create_or_join_responsible_person
  skip_before_action :authenticate_user!, only: %i[join]

  def new; end

  def create
    @responsible_person.save
    if @responsible_person.errors.empty?
      send_invite_email
      redirect_to responsible_person_team_members_path(@responsible_person)
    else
      render :new
    end
  end

  def join
    pending = PendingResponsiblePersonUser.find(params[:id])
    # TODO: What to do when the invitation is expired?
    invited_user = SubmitUser.find_by(email: pending.email_address)

    return render("join_signed_in_as_another_user", locals: { existing_user: invited_user }) if current_user && current_user.email != pending.email_address
    return redirect_to registration_new_submit_user_path unless invited_user
    return authenticate_user! unless current_user

    # User at this point is signed as the invited user.
    @responsible_person.add_user(current_user)
    Rails.logger.info "Team member added to Responsible Person"
    # TODO: Check if we need to enable cleaning multiple pending invitations as before:
    # pending_requests.delete_all

    redirect_to responsible_person_path(@responsible_person)
  end

  def sign_out_before_joining
    sign_out
    redirect_to join_responsible_person_team_member_path(params[:responsible_person_id], params[:id])
  end

private


  def set_responsible_person
    @responsible_person = ResponsiblePerson.find(params[:responsible_person_id])
  end

  def authorize_responsible_person
    authorize @responsible_person, :show?
  end

  def team_member_params
    params.fetch(:team_member, {}).permit(
      :email_address,
    )
  end

  def set_team_member
    @team_member = @responsible_person.pending_responsible_person_users.build(team_member_params)
  end

  def send_invite_email
    NotifyMailer.send_responsible_person_invite_email(
      @responsible_person,
      @team_member,
      current_user.name,
    ).deliver_later
  end
end

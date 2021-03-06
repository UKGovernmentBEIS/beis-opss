class ResponsiblePersonsController < SubmitApplicationController
  before_action :set_responsible_person, only: %i[show]
  skip_before_action :create_or_join_responsible_person, only: %i[select change]
  before_action :validate_responsible_person

  def show; end

  def select; end

  def change
    set_current_responsible_person(current_user.responsible_persons.find(params[:id]))
    redirect_to responsible_person_notifications_path(current_responsible_person)
  end

private

  def set_responsible_person
    @responsible_person = ResponsiblePerson.find(params[:id])
    authorize @responsible_person
  end
end

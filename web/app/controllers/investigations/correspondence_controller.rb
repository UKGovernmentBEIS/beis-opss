class Investigations::CorrespondenceController < ApplicationController
  include Wicked::Wizard
  steps :surface, :content, :confirmation

  def new
    clear_session
    session[:investigation_id] = params[:investigation_id]
    redirect_to wizard_path(steps.first, request.query_parameters)
  end

  def create
    load_investigation_and_correspondence
    @investigation.correspondences << @correspondence
    @investigation.save
    clear_session
    redirect_to investigation_path(@investigation)
  end

  def show
    load_investigation_and_correspondence
    @correspondence = Correspondence.new(session[:correspondence])
    render_wizard
  end

  def update
    load_investigation_and_correspondence
    if !@correspondence.valid?(step)
      render step
    else
      redirect_to next_wizard_path
    end
  end

private

  def correspondence_params
    return {} if !params[:correspondence].present?
    handle_type_params
    handle_date_params
    params.require(:correspondence).permit(
      :correspondent_name, :correspondent_type, :contact_method, :phone_number, :email_address, :correspondence_date,
      :overview, :details
    )
  end

  def handle_type_params
    if params[:correspondence][:correspondent_type] == 'Other'
      params[:correspondence][:correspondent_type] = params[:correspondence][:other_correspondent_type]
    end
  end

  def handle_date_params
    year = params[:correspondence][:correspondence_date_year]
    month = params[:correspondence][:correspondence_date_month]
    day = params[:correspondence][:correspondence_date_day]
    if(year.present? && month.present? && day.present?)
      params[:correspondence][:correspondence_date] = Date.new(year.to_i, month.to_i, day.to_i)
    end
  end

  def load_investigation_and_correspondence
    @investigation = Investigation.find_by(id: session[:investigation_id])
    load_correspondence
  end

  def load_correspondence
    data_from_database = values_from_flow || {}
    data_from_previous_steps = data_from_database.merge(session[:correspondence] || {})
    data_after_last_step = data_from_previous_steps.merge(correspondence_params || {})
    params[:correspondence] = data_after_last_step
    session[:correspondence] = correspondence_params
    @correspondence = Correspondence.new(session[:correspondence])
  end

  def values_from_flow
    values = { correspondence_date: Date.today }

    @reporter = @investigation.reporter
    values = values.merge({
      correspondent_name: @reporter.name,
      contact_method: get_contact_method,
      phone_number: @reporter.phone_number,
      email_address: @reporter.email_address
    }) if @reporter
    values
  end

  def get_contact_method
    if @reporter.email_address.present?
      return "Email"
    elsif @reporter.phone_number.present?
      return "Phone call"
    else
      return nil
    end
  end

  def clear_session
    session[:correspondence] = nil
    session[:investigation_id] = nil
  end
end

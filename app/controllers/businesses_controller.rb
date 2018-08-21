class BusinessesController < ApplicationController
  include BusinessesHelper
  before_action :authenticate_user!
  before_action :set_business, only: %i[show edit update destroy]
  before_action :create_business, only: %i[create]
  before_action :update_business, only: %i[update]

  BUSINESS_SUGGESTION_LIMIT = 5

  # GET /businesses
  # GET /businesses.json
  def index
    @businesses = if params[:q].blank?
                    Business.paginate(page: params[:page], per_page: 20)
                  else
                    search_for_businesses(20)
                  end
  end

  # GET /businesses/1
  # GET /businesses/1.json
  def show
    return unless @business.from_companies_house?
    PaperTrail.request.whodunnit = nil # This will stop papertrail recording the current user
    CompaniesHouseClient.instance.update_business_from_companies_house(@business)
  end

  # GET /businesses/confirm_merge
  def confirm_merge
    @businesses = Business.find(params[:business_ids])
  end

  # POST /businesses/merge
  def merge
    selected_business = Business.find(params[:selected_business_id])

    other_business_ids = params[:business_ids].select { |id| id != selected_business.id }
    other_businesses = Business.find(other_business_ids)

    other_businesses.each do |other_business|
      selected_business.merge!(other_business, attributes: selected_business.attributes.keys, associations: %w[addresses investigation_businesses])
    end

    redirect_to businesses_url, notice: "Businesses were successfully merged."
  end

  # GET /businesses/new
  def new
    @business = Business.new
    @business.addresses.build
  end

  # GET /businesses/1/edit
  def edit
    @business.addresses.build unless @business.addresses.any?
  end

  # GET /businesses/search
  def search
    @existing_businesses = search_for_businesses(BUSINESS_SUGGESTION_LIMIT)
    companies_house_response = CompaniesHouseClient.instance.companies_house_businesses(params[:q])
    @companies_house_businesses = filter_out_existing_businesses(companies_house_response)
                                  .first(BUSINESS_SUGGESTION_LIMIT)
    render partial: "search_results"
  end

  # POST /businesses/companies_house
  def companies_house
    @business = CompaniesHouseClient.instance.create_business_from_companies_house_number params[:company_number]
    respond_to_business_creation
  end

  # POST /businesses
  # POST /businesses.json
  def create
    respond_to_business_creation
  end

  # PATCH/PUT /businesses/1
  # PATCH/PUT /businesses/1.json
  def update
    respond_to do |format|
      if @business.save
        format.html { redirect_to @business, notice: "Business was successfully updated." }
        format.json { render :show, status: :ok, location: @business }
      else
        format.html { render :edit }
        format.json { render json: @business.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /businesses/1
  # DELETE /businesses/1.json
  def destroy
    @business.destroy
    respond_to do |format|
      format.html { redirect_to businesses_url, notice: "Business was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def create_business
    @business = Business.new(business_params)
    set_defaults_on_primary_address if @business.addresses.any?
    @business.source = UserSource.new(user: current_user)
  end

  def set_business
    @business = Business.find(params[:id])
  end

  def update_business
    @business.assign_attributes(business_params)
    set_defaults_on_primary_address if @business.addresses.any?
  end

  def search_for_businesses(page_size)
    Business.search(params[:q])
            .paginate(page: params[:page], per_page: page_size)
            .records
  end

  def respond_to_business_creation
    respond_to do |format|
      if @business.save
        format.html { redirect_to @business, notice: "Business was successfully created." }
        format.json { render :show, status: :created, location: @business }
      else
        format.html { render :new }
        format.json { render json: @business.errors, status: :unprocessable_entity }
      end
    end
  end

  def filter_out_existing_businesses(businesses)
    businesses.reject { |business| Business.exists?(company_number: business[:company_number]) }
  end

  def set_defaults_on_primary_address
    @business.primary_address.address_type ||= "Registered office address"
    @business.primary_address.source ||= UserSource.new(user: current_user)
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def business_params
    params.require(:business).permit(
      :company_name,
      :company_type_code,
      :nature_of_business_id,
      :additional_information,
      addresses_attributes: %i[id line_1 line_2 locality country postal_code _destroy]
    )
  end
end

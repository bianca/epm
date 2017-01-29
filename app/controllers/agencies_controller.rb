class AgenciesController < ApplicationController

  load_and_authorize_resource :agency

  def index
  end
 
  def show
   @events = @agency.events.not_past
  end

  def new
  end

  def edit
  end

  def order
      in_the_last_week = DateTime.now - 7.days
      now = DateTime.now
      @agencies = Agency.closest [params['lat'], params['lng']]
      @agencies.each {|a| a.alreadyrecieved = a.alreadyrecieved? in_the_last_week, now }
      # get all agencies with number of picks for that agency in the last week (order them by closeness)
      if params['day'].present?
        start_t = "#{params['day']} #{params['time']} #{params['time_p']}".to_datetime
        dayoftheweek = start_t.strftime("%A").downcase 
        end_t = start_t + ((params['duration'].to_i/3600)).hours
        @agencies.select!{|a| a.open? end_t, dayoftheweek}
      end
      render json: @agencies
  end

  def create
    @agency = Agency.new(agency_params)
    if @agency.save
      redirect_to @agency
    else 
      render :new 
    end
  end

  def update
    @agency.update(agency_params)
    redirect_to @agency
  end

  def destroy
    flash[:notice] = "#{@agency.title} deleted."
    @agency.destroy
    redirect_to @agency
  end

  private
    def set_agency
      @agency = Agency.find(params[:id])
    end

    def agency_params
      params.require(:agency).permit(:title, :description, :address, :lat, :lng, :mondayopen, :mondayclose, :tuesdayopen, :tuesdayclose, :wednesdayopen, :wednesdayclose, :thursdayopen, :thursdayclose, :fridayopen, :fridayclose, :saturdayopen, :saturdayclose, :sundayopen, :sundayclose)
    end
end

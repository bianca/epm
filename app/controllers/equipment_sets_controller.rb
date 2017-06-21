class EquipmentSetsController < ApplicationController

  load_and_authorize_resource :equipment_set

  def index
    @equipment_set_issues = EquipmentSet.where.not(issues: nil )
  end

  def show
    @events = @equipment_set.events.not_past
  end

  def new
    @equipment_set = EquipmentSet.new
  end

  def edit
  end

  def resolve_issue
    @equipment_set.issues = ""
    @equipment_set.save
    redirect_to action: "index"
  end


  def create
    @equipment_set = EquipmentSet.new(equipment_set_params)
    if @equipment_set.save
      redirect_to @equipment_set
    else 
      render :new
    end
  end

  def order
      @equipment_sets = EquipmentSet.closest [params['lat'], params['lng']] 
      if params['day'].present?
        start_t = Time.zone.parse "#{params['day']} #{params['time']} #{params['time_p']}"
        start_t = start_t - 1.hour
        end_t = start_t + ((params['duration'].to_i/3600)).hours + 1.hour 
        start_time = start_t
        end_time = end_t
        @equipment_sets = @equipment_sets.select{|eq| eq.available? start_t, end_t}
      end
      render json: @equipment_sets 
  end

  def update
    @equipment_set.update(equipment_set_params)
    redirect_to @equipment_set
  end

  def destroy
    flash[:notice] = "#{@equipment_set.title} deleted."
    @equipment_set.destroy
    redirect_to @equipment_set
  end

  private 
    def set_equipment_set
      @equipment_set = EquipmentSet.find(params[:id])
    end

    def equipment_set_params
      params.require(:equipment_set).permit(:title, :description, :address, :lat, :lng)
    end
end

class EquipmentSetsController < ApplicationController

  load_and_authorize_resource :equipment_set

  def index
  end

  def show
    @events = @equipment_set.events.not_past
  end

  def new
    @equipment_set = EquipmentSet.new
  end

  def edit
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

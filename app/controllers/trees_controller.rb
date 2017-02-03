class TreesController < ApplicationController
  # before_action :set_tree, only: [:show, :edit, :update, :destroy]

  load_and_authorize_resource :tree, except: :create
  authorize_resource :tree, only: :create
  authorize_resource :user
  # authorize_resource :tree

  # GET /trees
  def index
    @page = 1
    if params["page"].present?
      @page = params["page"]
    end
    @q = params['q'] ? params['q'].strip : nil   
    if @q.present?
      @trees = Tree.search(@q).page(@page).per(20)
    else 
      @trees = Tree.all().page(@page).per(20)
    end

    respond_to do |format|
      format.csv do
        send_data Tree.csv(Tree.distinct.joins(:owner))
      end
      format.html do

      end
    end
  end

  def inviteowner 
    if EventMailer.schedule_pick_with_user(@tree).deliver
      flash[:notice] = "Scheduling email sent to #{@tree.owner.fname} at #{@tree.owner.email}."
    else 
      flash[:error] = "Email not sent. Try again?"
    end
  end

  def mine
    @page = 1
    if params["page"].present?
      @page = params["page"]
    end
    @isowner = Tree.where({owner_id: current_user.id })
    @issubmitter = Tree.where({submitter_id: current_user.id })
  end

  # GET /trees/1
  def show
    @events = EventTree.where({tree_id: @tree.id}) #.order(:start)
  end

  # GET /trees/new
  def new
    #render text: current_user.to_yaml
    #return
    @tree.owner = current_user
    @tree.pickable = true
    #@tree.owner_id = current_user.id
  end

  # GET /trees/1/edit
  def edit
  end

  # GET /trees/1/copy
  def copy
    @new_tree = @tree.dup
    @new_tree.save
    @tree = nil
    @tree = @new_tree
    redirect_to action: 'edit', id: @tree.id
  end

  # GET /trees/1/copy_location
  def copy_location
    @new_tree = Tree.new
    @new_tree.owner = @tree.owner
    if @tree.owner_id != current_user.id
      @new_tree.submitter = current_user
    else 
      @new_tree.relationship = "propertyowner"
    end

    @new_tree.save
    redirect_to action: 'edit', id: @new_tree.id
  end

  def closest 
    @add = true
    @page = 1
    if params['page'].present? && params['page'].to_i > 1
      @page = params['page'].to_i
    end
    if params['ids'].blank?
      params['ids'] = []
    end
    @trees = Tree.closest([params['lat'],params['lng']], params['ids'], @page)
    render :_formlist, layout: false
  end

  # POST /trees
  def create
    @tree = Tree.new tree_params
    if @tree.pickable.blank?
      @tree.pickable = true
    end
    owner_params = params.require(:tree).permit(owner_attributes: [:id, :fname, :lname, :email, :phone, :ladder, :contactnotes, :propertynotes, :home_ward, :address, :lat, :lng])
    @tree.owner = User.find(owner_params["owner_attributes"]["id"].to_i)
    @tree.owner.attributes = owner_params["owner_attributes"]
    if @tree.owner.changed?
      # check if the name has changed, if so, create a new user
      if (@tree.owner.fname_changed? || @tree.owner.lname_changed?) && @tree.owner.email_changed?
        existing_user = User.where({ email: @tree.owner.email, address: @tree.owner.address})
        if existing_user.count > 0
          @tree.owner_id = existing_user.first.id
          @tree.submitter_id = current_user.id
        else 
          new_user_hash = @tree.owner.attributes
          new_user_hash.delete('id')
          new_user_hash.delete('confirmation_sent_at')
          new_user_hash.delete('confirmation_token')
          new_user_hash.delete('confirmed_at')
          new_user_hash.delete('current_sign_in_at')
          new_user_hash.delete('current_sign_in_ip')
          new_user_hash['created_at'] = DateTime.now
          new_user_hash['password'] = Devise.friendly_token.first(8)
          new_user = User.new(new_user_hash)
          new_user.skip_confirmation!

          if new_user.save
            if @tree.relationship == "tenant" || @tree.relationship == "friend" 
              new_user.roles.create name: :tree_owner
            end 
            @tree.owner_id = new_user.id
            @tree.submitter_id = current_user.id
          end
        end
      end
    end

    if @tree.save
      redirect_to @tree, notice: 'Tree was successfully created.'
    else
      render :new
    end
  end

  # PATCH/PUT /trees/1
  def update
    if @tree.update(tree_params)
      redirect_to @tree, notice: 'Tree was successfully updated.'
    else
      render :edit
    end
  end

  # DELETE /trees/1
  def destroy
    @tree.destroy
    if can? :index, Tree
      redirect_to trees_url, notice: 'Tree was successfully destroyed.'
    else 
      redirect_to mine_trees_url, notice: 'Tree was successfully destroyed.'
    end
  end

  def dashboard


  end

  private
    # Use callbacks to share common setup or constraints between actions.
    # def set_tree
    #   @tree = Tree.find(params[:id])
    # end

    # Only allow a trusted parameter "white list" through.
    def tree_params
      params.require(:tree).permit(:height, :species, :species_other, :subspecies, :relationship, :treatment, :keep, :additional, :pickable, :not_pickable_reason, :ripen) # , owner_attributes: [:id, :fname, :lname, :email, :phone, :ladder, :contactnotes, :propertynotes, :home_ward, :address, :lat, :lng]
    end
end

class AddPostPickFields < ActiveRecord::Migration
  def change
  	add_column :events, :fun, :integer, default: 0
  	add_column :events, :first_aid, :text 
  	add_column :events, :lbs_to_agency, :integer 
  end
end

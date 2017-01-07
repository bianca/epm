class AddPickTreeAssociation < ActiveRecord::Migration
  def change 
  	  add_column :event_trees, :quality, :integer
  	  add_column :event_trees, :quality_issues, :text
      add_column :event_trees, :lbs_picked, :float
  end
end

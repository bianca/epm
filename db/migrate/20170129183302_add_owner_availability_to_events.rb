class AddOwnerAvailabilityToEvents < ActiveRecord::Migration
  def change
  	add_column :events, :owner_availability, :text
  	add_column :events, :owner_availability_start, :datetime
  end
end

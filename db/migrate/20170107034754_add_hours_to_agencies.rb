class AddHoursToAgencies < ActiveRecord::Migration
  def change
  	add_column :agencies, :mondayopen, :time
  	add_column :agencies, :mondayclose, :time
  	add_column :agencies, :tuesdayopen, :time
  	add_column :agencies, :tuesdayclose, :time
  	add_column :agencies, :wednesdayopen, :time
  	add_column :agencies, :wednesdayclose, :time
  	add_column :agencies, :thursdayopen, :time
  	add_column :agencies, :thursdayclose, :time
  	add_column :agencies, :fridayopen, :time
  	add_column :agencies, :fridayclose, :time
  	add_column :agencies, :saturdayopen, :time
  	add_column :agencies, :saturdayclose, :time
  	add_column :agencies, :sundayopen, :time
  	add_column :agencies, :sundayclose, :time
  end
end

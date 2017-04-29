class AddEquipmentsetissueToEquipmentsets < ActiveRecord::Migration
  def change
  	add_column :equipment_sets, :issues, :text
  end
end

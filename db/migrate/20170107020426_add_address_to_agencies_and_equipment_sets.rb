class AddAddressToAgenciesAndEquipmentSets < ActiveRecord::Migration
  def change
    add_column :agencies, :address, :text
    add_column :agencies, :lat, :decimal, :precision => 9, :scale => 6
    add_column :agencies, :lng, :decimal, :precision => 9, :scale => 6
    add_index :agencies, [:lat, :lng]
    add_column :equipment_sets, :address, :text
    add_column :equipment_sets, :lat, :decimal, :precision => 9, :scale => 6
    add_column :equipment_sets, :lng, :decimal, :precision => 9, :scale => 6
  end
end

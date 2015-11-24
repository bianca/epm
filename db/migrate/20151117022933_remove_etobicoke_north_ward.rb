class RemoveEtobicokeNorthWard < ActiveRecord::Migration
  def change
  	Ward.where("name LIKE '%Etobicoke North'").destroy_all
  end
end

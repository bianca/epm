class EquipmentSet < ActiveRecord::Base
	has_many :events
	strip_attributes

	validates :title, :presence => true
  acts_as_mappable :distance_field_name => :distance
  
  def coords()
    return nil if lat.blank? || lng.blank?
    [lat, lng]
  end

  def self.closest(origin)
	EquipmentSet.by_distance(:origin => origin)
  end

end

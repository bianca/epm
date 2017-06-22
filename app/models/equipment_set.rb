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

  def available?(start_time, end_time, event_id)
    self.events.each do |event|
      if event.start.present? && event.finish.present?
          es = event.start.to_datetime.in_time_zone - 1.hour
          ef = event.finish.to_datetime.in_time_zone + 1.hour
          if event.id.to_i != event_id.to_i && ((start_time <= es && end_time >= es) || (start_time <= ef && end_time >= ef)  || (start_time >= es && start_time <= ef)|| (end_time >= es && end_time <= ef))
            return false
          end
      end
    end
    return true
  end

end

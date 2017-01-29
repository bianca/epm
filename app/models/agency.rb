class Agency < ActiveRecord::Base
	has_many :events
	strip_attributes

	validates :title, :presence => true
  acts_as_mappable :distance_field_name => :distance
  
  attr_accessor :distance, :alreadyrecieved

  def coords()
    return nil if lat.blank? || lng.blank?
    [lat, lng]
  end

  def self.closest(origin)
  	@agencies = Agency.by_distance(:origin => origin)
    @agencies.each do |a|
      a.distance = a.distance_to(origin)
    end
  end

  def alreadyrecieved?(in_the_last_week, now)
    event_count = Event.where("events.agency_id = ? and events.start > ? and events.start < ?", id, in_the_last_week, now).reorder('').count()
    puts event_count
      return event_count > 0
  end

  def open?(time, dayoftheweek)
      if send(dayoftheweek+"open").present? and send(dayoftheweek+"close").present?
        if Time.parse(send(dayoftheweek+"open").strftime("%I:%M%p")) < Time.parse(time.strftime("%I:%M%p")) and Time.parse(send(dayoftheweek+"close").strftime("%I:%M%p")) > Time.parse(time.strftime("%I:%M%p"))
          return true
        else 
          return false
        end
      else 
        return false
      end
  end

def as_json(options = { })
    # just in case someone says as_json(nil) and bypasses
    # our default...
    super((options || { }).merge({
        :methods => [:alreadyrecieved]
    }))
end

end

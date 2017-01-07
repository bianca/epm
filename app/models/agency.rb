class Agency < ActiveRecord::Base
	has_many :events
	strip_attributes

	validates :title, :presence => true

  def coords()
    return nil if lat.blank? || lng.blank?
    [lat, lng]
  end

end

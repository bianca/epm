class Agency < ActiveRecord::Base
	has_many :events
	strip_attributes
end
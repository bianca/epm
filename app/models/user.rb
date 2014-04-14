class User < ActiveRecord::Base

  devise :database_authenticatable, :registerable, :confirmable, :recoverable, :rememberable, :trackable, :validatable

  strip_attributes
  before_create do |user|
    if user.name.blank? && user.email.present? && user.email.include?('@')
      user.name = user.email.split('@').first.gsub(/\.|-|_/, ' ').titlecase
    end
    true
  end

  def self.csv
    CSV.generate force_quotes: true do |csv|
      csv << ['id', 'name', 'email', 'phone number', 'joined', 'events attended', 'roles', 'description']
      all.each do |user|
        csv << [user.id, user.name, user.email, user.phone, user.created_at.to_date.to_s, user.events.past.count, user.roles.map{|r| r.name}.join(', '), user.description]
      end
    end
  end

  # this section identical to that in model event.rb
  acts_as_mappable
  attr_accessor :no_geocode # force geocoding to not happen. used for testing
  after_validation :geocode, if: "!no_geocode && address_changed? && address.present? && (lat.blank? || lng.blank?)"
  validates :lat, numericality: {greater_than_or_equal_to: -90, less_than_or_equal_to: 90}, allow_nil: true
  validates :lng, numericality: {greater_than_or_equal_to: -180, less_than_or_equal_to: 180}, allow_nil: true


  scope :by_name, -> { order :name }
  scope :search, ->(q) {
    like = Rails.configuration.database_configuration[Rails.env]["adapter"] == 'postgresql' ? 'ILIKE' : 'LIKE'
    where("users.email LIKE ? OR users.name #{like} ?", "%#{q}%", "%#{q}%")
  }
  scope :roleless, -> { where 'users.id NOT IN (SELECT DISTINCT user_id FROM roles)' }
  # todo: consider refactoring these to automatically have a scope for every role
  scope :admins, -> { joins("INNER JOIN roles ON roles.user_id = users.id AND roles.name = #{Role.names[:admin]}") }
  scope :coordinators, -> { joins("INNER JOIN roles ON roles.user_id = users.id AND roles.name = #{Role.names[:coordinator]}") }
  scope :participants, -> { joins("INNER JOIN roles ON roles.user_id = users.id AND roles.name = #{Role.names[:participant]}") }

  has_many :event_users, dependent: :destroy
  has_many :coordinating_events, class_name: 'Event', foreign_key: 'coordinator_id'
  # events where the user is a participant (will attend or did attend) or the coordinator
  def events
    Event.not_cancelled.joins("LEFT JOIN event_users ON events.id = event_users.event_id AND event_users.status IN (#{EventUser.statuses[:attending]}, #{EventUser.statuses[:attended]})").where("events.coordinator_id = ? OR event_users.user_id = ?", id, id).distinct
  end

  def open_invites # upcoming events the user has been invited to
    Event.not_past.not_cancelled.joins(:event_users)
      .where(
        'event_users.status' => EventUser.statuses[:invited],
        'event_users.user_id' => id
      )
  end
  def potential_events # upcoming events where waitlisted or requested to attend
    Event.not_past.not_cancelled.joins(:event_users)
      .where(
        'event_users.status' => [EventUser.statuses[:waitlisted], EventUser.statuses[:requested]],
        'event_users.user_id' => id
      )
  end


  has_many :roles, dependent: :destroy
  accepts_nested_attributes_for :roles
  attr_accessor :no_roles
  after_create :set_default_role, if: "roles.empty? && !no_roles"
  def set_default_role
   if self.class.count == 1
      self.roles.create name: :admin
    else
      self.roles.create name: :participant
    end
  end
  def has_role?(role_name)
    !self.roles.find{|r| r.send "#{role_name}?" }.nil?
  end

  def display_name
    name || '(no name)'
  end

  def avatar(size = :small)
    sizes = {small: 48, large: 80}
    "http://gravatar.com/avatar/#{CGI.escape(Digest::MD5.hexdigest(email.downcase))}?s=#{sizes[size]}&d=mm"
  end

  def ability # allows checking permissions for this user rather than the current
    @ability ||= Ability.new(self)
  end

  def coords
    (lat.present? && lng.present?) ? [lat, lng] : nil
  end

  private

    # this method identical to that in model event.rb
    def geocode
      geo = Geokit::Geocoders::MultiGeocoder.geocode address.gsub(/\n/, ', ')
      if geo.success
        self.lat, self.lng = geo.lat, geo.lng
      else
        errors.add(:address, 'Problem locating address')
      end
    end


end
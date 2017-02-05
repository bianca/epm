class EventUser < ActiveRecord::Base

  belongs_to :event
  belongs_to :user
  validates :user_id, :event_id, presence: true
  validates :user_id, uniqueness: { scope: :event }


  # note: :requested, :denied, :attended, and :no_show are largely unimplemented
  enum status: [
    :invited,       # 0 admin/coordinator has invited the participant
    :requested,     # 1 the participant has requested to attend, for events which require admin/coordinator approval
    :attending,     # 2 participant will attend (or if the event has passed, was planning to attend and may have)
    :not_attending, # 3 admin/coordinator has invited the participant, who said 'no'
    :waitlisted,    # 4 participant would like to attend (or to have attended) but event is full
    :denied,        # 5 admin/coordinator has denied the participant the ability to participate
    :withdrawn,     # 6 participant had requested or been waitlisted, but then withdrew their request
    :cancelled,     # 7 participant had been 'attending' but changed their rsvp to 'no'
    :attended,      # 8 participant had intended to attend, and did so
    :no_show,        # 9 participant had intended to attend, but never showed up
    :dropout,        # 10 participant was intending to attend, but dropped out within 24 hours
    :autonoshow        # 11 participant was automatically signed up from waitlist in the last 24 hours, but was a noshow
  ]

  validates :status, presence: true
  def self.statuses_array(*syms) # shortcut for an array of multiple status values
    syms.map{|s| statuses[s]}
  end


  scope :noshow, -> {
    where(status: statuses[:no_show])
    .joins("LEFT JOIN events ON event_users.event_id = events.id")
    .select("extract(YEAR from events.start) AS year, count(event_users.id) as count")
    .group(:year)
  }


  def attend
    #return false if event.past?
    # todo: does not handle :requested status
    was_attending = attending?
    if [nil, 'invited', 'not_attending', 'withdrawn', 'cancelled'].include? status
      self.status = event.full? ? :waitlisted : :attending
      if save && !was_attending && attending?
        event.calculate_participants
      end
    end
    notify_coordinator(event)
    self
  end

  def unattend(action_by_self = true)
    was_attending = attending?
    if invited?
      self.status = action_by_self ? :not_attending : :denied
    elsif attending? || (event.start-Time.zone.now)/3600 < 24
      self.status = action_by_self ? :dropout : :denied      
    elsif attending? || no_show?
      self.status = action_by_self ? :cancelled : :denied
    elsif waitlisted? || requested?
      self.status = action_by_self ? :withdrawn : :denied
    end
    if self.status && save && was_attending && !attending? && !event.past?
      event.add_from_waitlist if event.time_until > 5.hours # todo: allow configurability of this number
      EventMailer.unattend(event, user).deliver unless action_by_self      
      event.calculate_participants
    end
    notify_coordinator(event)
    self
  end

  def notify_coordinator event
    if event.time_until < 24.hours
      EventMailer.attendance_changes(event, [event.coordinator]).deliver 
    end
  end

end
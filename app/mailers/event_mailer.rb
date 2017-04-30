class EventMailer < ActionMailer::Base

  default from: "#{Configurable.title} <#{Configurable.email}>"

  include ActionView::Helpers::TextHelper # needed for pluralize()

  # in many of these methods, @user is for checking permissions -
  #   usually passing in an array of users who all have the same permissions so can just use the first

  def attend(event, users)
    @users = [*users]
    @event = event
    # users are all participants, but as some could also be admins, need to do this for permissions:
    @user = @users.find{|u| u.ability.cannot?(:read_notes, event)} || @users.first
    mail bcc: to(users), subject: "Attending: #{event.display_name(@user)} at #{@event.start.strftime('%a %b %e %l:%M %p')}"
  end

  def unattend(event, users, reason = nil)
    @event = event
    @reason = reason
    mail bcc: to(users), subject: "You are no longer attending #{event.display_name}"
  end

  def coordinator_needed(event, users)
    @event = event
    @user = users.first
    mail bcc: to(users), subject: "You are invited to lead #{@event.display_name(@user)}"
  end

  def coordinator_assigned(event)
    @event = event
    mail to: to(@event.coordinator), subject: "You have been assigned to lead #{@event.display_name(@event.coordinator)}"
  end

  def volunteer_notes(event, notes, admins)
    @event = event
    @notes = notes
    mail to: to(admins), subject: "Volunteer notes in post-pick details for #{@event.display_name(@event.coordinator)} "
  end

  def equipment_set_notes(event, notes, admins)
    @event = event
    @notes = notes
    mail to: to(admins), subject: "Equipment set issue in post-pick details for #{@event.display_name(@event.coordinator)} "
  end

  def cancel(event, users)
    @event = event
    @user = users.first
    mail bcc: to(users), subject: "#{@event.display_name(@user)} has been cancelled"
  end

  def change(event, users)
    @event = event
    @user = users.first
    mail bcc: to(users), subject: "Changes to #{@event.display_name(@user)}"
  end

  def awaiting_approval(event, users)
    @event = event
    @user = users.first
    mail bcc: to(users), subject: "#{@event.display_name(@user)} is awaiting approval"
  end

  def approve(event)
    @event = event
    mail to: to(event.coordinator), subject: "Approved: #{@event.display_name(event.coordinator)}"
  end

  def invite(event, user)
    @event = event
    @user = user
    eu = @event.event_users.create user: user, status: :invited
    mail to: to(user), subject: "#{event.display_name(@user)} at #{@event.start.strftime('%a %b %e %l:%M %p')}"
  end

  def remind(event, users = nil)
    @event = event
    users ||= @event.users
    @user = users.find{|u| u.ability.cannot?(:read_notes, event)} || users.first
    mail bcc: to(users), subject: "Reminder: #{event.display_name} is in #{pluralize event.hours_until, 'hour'}"
  end

  def attendance_changes(event, users = nil)
    @event = event
    users ||= @event.users
    @user = users.find{|u| u.ability.cannot?(:read_notes, event)} || users.first
    mail bcc: to(users), subject: "Reminder: #{event.display_name} is in #{pluralize event.hours_until, 'hour'}"
  end

  def schedule_pick_with_user(tree)
    @tree = tree
    mail to: to(tree.owner), subject: "Can we schedule a pick for your #{tree.species} tree?"
  end

  private

    def to(users)
      return users.map{|u| to(u)} unless users.is_a? User
      n = "#{users.fname} #{users.lname}".strip
      n.present? ? "#{n} <#{users.email}>" : users.email
    end

end

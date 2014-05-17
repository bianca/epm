class EventsController < ApplicationController
 
  load_and_authorize_resource :event

  def index
    respond_to do |format|
      format.html do
        if current_user.has_role? :admin
          # this 'section' doesn't match the pattern of the others so can't be put into @sections
          coordinators = User.coordinators_not_taking_attendance
          @coordinators_not_taking_attendance = coordinators if coordinators.any?
        end
        @sections = []
        max = 10 # used for sections which do not need to show all
        if current_user.has_role? :admin
          @sections << { q: Event.awaiting_approval, name: 'Awaiting Approval' }
        end
        if current_user.has_role? :participant
          @sections << { q: current_user.open_invites, name: 'Invited' }
        end
        if current_user.has_role? :coordinator
          @sections << { q: current_user.coordinating_events.needing_attendance_taken, name: 'Needing Attendance Taken' }
          @sections << { q: current_user.coordinating_events.not_past, name: "Run by Me", id: 'coordinating' }
        end
        if current_user.has_role? :participant
          @sections << { q: current_user.participating_events.not_past, name: 'Attending' }
          @sections << { q: current_user.potential_events, name: 'May be Attending' }
        end
        if current_user.has_any_role? :coordinator, :admin
          @sections << { q: Event.where(coordinator_id: nil).not_past.not_cancelled, name: "Needing a #{Configurable.coordinator.titlecase}" }
        end
        if current_user.has_role? :admin
          @sections << { q: Event.where.not(coordinator_id: nil).where('start IS NULL OR lat IS NULL').not_past.not_cancelled, name: 'Missing a Date or Location' }
        end
        if current_user.has_any_role? :admin, :participant
          q = Event.needing_participants
          q = q.participatable_by(current_user) unless current_user.has_role? :admin
          @sections << { q: q, name: "Needing More #{Configurable.participant.pluralize.titlecase}" }
        end
        if current_user.has_any_role? :admin, :participant
          q = Event.accepting_not_needing_participants.limit(max)
          q = q.participatable_by(current_user) unless current_user.has_role? :admin
          @sections << { q: q, name: "Accepting More #{Configurable.participant.pluralize.titlecase}" }
        end
        if current_user.has_any_role? :admin, :participant
          q = Event.participatable.not_past.where(reached_max: true).limit(max)
          q = q.participatable_by(current_user) unless current_user.has_role? :admin
          @sections << { q: q, name: 'Upcoming', id: 'full' }
          @sections[0..-2].each do |section| # add the word 'more' to the name if there were any events already listed
            if section[:q].any?
              @sections.last[:name] = "More #{@sections.last[:name]}"
              break
            end
          end
        end
        if current_user.has_role? :admin
          @sections << { q: Event.participatable.past.limit(max) , name: 'Past' }
        end
      end
      format.ics do
        # todo: implement access token https://blog.nop.im/entries/calendar-feed-with-rails
        cal = Icalendar::Calendar.new
        cal.properties["X-WR-CALNAME"] = Configurable.title
        cal.properties["NAME"] = Configurable.title
        Event.with_date.each {|event| cal.add_event event.to_ical(request.host) }
        render text: cal.to_ical
      end
    end
  end

  def calendar
    @events = Event.not_cancelled.in_month params['year'], params['month']
  end

  def show
  end

  def who
    @can_take_attendance = false
    @taking_attendance = false
    @show_invites = false
    @show_invite = false
    if @event.start
      if (current_user.has_role?(:admin) || @event.coordinator == current_user) && @event.can_accept_participants?
        eus = @event.event_users.where(status: EventUser.statuses_array(:invited, :not_attending)).group_by{|eu| eu.status}
        @num_invited = (eus['invited'] || []).length
        @num_declined = (eus['not_attending'] || []).length
        @show_invites = (@num_invited > 0) || (@num_declined > 0)
      end
      if can?(:invite, @event) && @event.should_invite?
        @show_invite = true
      elsif @event.past?
        @can_take_attendance = can?(:take_attendance, @event) && @event.approved? && @event.event_users.where(status: EventUser.statuses_array(:attending, :attended, :no_show)).any?
        @taking_attendance = @can_take_attendance && (params['take_attendance'] || @event.event_users.where(status: EventUser.statuses[:attending]).any?)
      end
    end
  end

  def new
    attrs = {}
    attrs[:start] = "#{params['start_day']} #{Event.default_time}" if params['start_day']
    @event = Event.new(attrs)
  end

  def edit
  end

  def create
    redirect_to(root_path, notice: 'Event not saved.') and return if params['commit'] && params['commit'].downcase == 'cancel'
    @event = Event.new event_params
    if @event.save
      if @event.coordinator && @event.coordinator != current_user && !@event.past?
        EventMailer.coordinator_assigned(@event).deliver
      end
      redirect_to @event, notice: 'Event saved.'
    else
      render :new
    end
  end

  def update
    redirect_to(@event, notice: 'Event changes not saved.') and return if params['commit'] && params['commit'].downcase == 'cancel'
    @event.track
    if @event.update event_params
      # send email notifications if appropriate
      unless @event.cancelled?
        users = @event.users.reject{|u| u == current_user}
        # alert admins if it's ready for approval
        if !@event.prior['awaiting_approval?'] && @event.awaiting_approval?
          admins = User.admins.reject{|u| u == current_user}
          if admins.any?
            # note: awaiting approval emails also sent from claim method
            users.reject!{|u| admins.include? u} # prevents emailing an admin twice if they are also a coordinator or a participant of this event
            EventMailer.awaiting_approval(@event, admins).deliver
          end
        end
        # alert coordinator being assigned
        if @event.coordinator && (@event.coordinator_id != @event.prior['coordinator_id']) && (@event.coordinator != current_user) && !@event.past?
          users.reject!{|u| u == @event.coordinator} # prevents emailing a coordinator twice when they are assigned an event which has significant changes
          EventMailer.coordinator_assigned(@event).deliver
        end
        # alert other attendees
        if params['commit'] && params['commit'].downcase.include?('notify') && !(@event.past? && @event.prior['past?']) && users.any?
          users = users.partition{|u| u.ability.can?(:read_notes, @event)} # .first can read the note, .last can't
          changed_significantly = @event.changed_significantly?
          if (changed_significantly || (@event.notes != @event.prior['notes'])) && users.first.any?
            EventMailer.change(@event, users.first).deliver
          end
          if changed_significantly && users.last.any?
            EventMailer.change(@event, users.last).deliver
          end
        end
      end
      redirect_to @event, notice: 'Event saved.'
    else
      render :edit
    end
  end

  def approve
    if @event.proposed?
      @event.update status: :approved
      if @event.coordinator && @event.coordinator != current_user
        EventMailer.approve(@event).deliver
      end
      flash[:notice] = 'Event approved.'
      if @event.should_invite?
        if @event.invite > 0
          flash[:notice] += ' Invitations will be sent.'
        end
      end
    elsif @event.cancelled?
      flash[:notice] = 'Cannot approve cancelled events.'
    end
    redirect_to @event
  end

  def claim
    was_awaiting_approval = @event.awaiting_approval?
    if @event.update coordinator_id: current_user.id
      if @event.awaiting_approval? && !was_awaiting_approval
        # awaiting approval emails also sent from update method
        admins = User.admins.reject{|u| u == current_user}
        EventMailer.awaiting_approval(@event, admins).deliver if admins.any?
      end
      flash[:notice] = 'You are now running this event.'
    else
      flash[:error] = 'You are not able to claim this event.'
    end
    redirect_to @event
  end

  def ask_to_cancel
  end

  def cancel
    if params['commit'] && params['commit'] == 'Cancel Event'
      @event.update params.require(:event).permit(:cancel_notes, :cancel_description).merge(status: :cancelled)
      users = (@event.users + User.admins).reject{|u| u == current_user}
      users = users.partition{|u| u.ability.can?(:read_notes, @event)} # .first can read the note, .last can't
      EventMailer.cancel(@event, users.first).deliver if users.first.any?
      EventMailer.cancel(@event, users.last).deliver if users.last.any?
      flash[:notice] = 'Event cancelled.'
    else
      flash[:notice] = 'Event not cancelled.'
    end
    redirect_to @event
  end

  def attend
    eu = @event.attend current_user
    EventMailer.attend(@event, current_user).deliver if eu.attending?
    # note: no need for flash messages as that is redundant with the rsvp text in events#show
    redirect_to @event
  end

  def unattend
    @event.unattend current_user
    # note: no need for flash messages as that is redundant with the rsvp text in events#show
    redirect_to @event
  end

  include ActionView::Helpers::TextHelper # needed for pluralize()
  def invite
    invites = @event.invite
    if invites > 0
      flash[:notice] = "#{pluralize invites, 'invitation'} will be sent."
    else
      flash[:notice] = 'No invitations sent.'
    end
    redirect_to who_event_path @event
  end

  def take_attendance
    params['attendance'] ||= []
    attended_eu_ids = params['attendance'].map{|eu_id, v| eu_id.to_i}
    @event.take_attendance attended_eu_ids
    redirect_to who_event_path(@event), notice: 'Attendance taken.'
  end

  private

    def event_params
      # should actually only enable :status to be set by admin. todo
      params.require(:event).permit(:name, :description, :notes, :start, :start_day, :start_time_12, :start_time_p, :duration, :finish, :coordinator_id, :notify_of_changes, :status, :address, :lat, :lng, :hide_specific_location, :min, :max, :ward_id)
    end

end
module Mybookings
  class Booking < ActiveRecord::Base
    include Loggable

    belongs_to :user
    belongs_to :resource_type
    has_many :events , inverse_of: :booking

    delegate :email, to: :user, prefix: true
    delegate :name, to: :resource_type, prefix: true
    delegate :extension, to: :resource_type, prefix: true
    delegate :users, to: :resource_type, prefix: true

    validates :start_date, :end_date, :resource_id, :recurrent_type, presence: true
    validates :until_date, presence: true, if: :is_a_recurring_booking?
    validate :the_booking_period_is_valid, if: :is_a_recurring_booking?
    validate :the_event_duration_is_valid
    validate :until_date_in_the_future, on: :create
    validate :events_are_valid

    attr_accessor :resource_id

    enum recurrent_type: %w(daily weekly monthly)

    self.inheritance_column = :booking_type

    def self.by_start_date_group_by_resource_type
      includes(:events, :resource_type).order('mybookings_resource_types.name ASC').group_by(&:resource_type)
    end

    def self.new_for_user user, params
      booking = self.new(params)
      booking.user = user
      booking.generate_events if booking.valid?

      booking
    end

    def self.unprepared
      where(prepared: false)
    end

    def delete_pending_events
      events_to_delete = events.where(status: 0)
      events_to_delete.each do |event|
        event.cancel!
      end
      events_to_delete.destroy_all
    end

    def has_pending_events?
      events.pending.count > 0
    end

    def has_events?
      events.any?
    end

    def generate_events
      dates = generate_dates

      event_duration = end_date - start_date

      new_events = Array.new

      dates.each do |date|
        new_events << { start_date: string_format(date),
                        end_date: string_format(date + event_duration.seconds),
                        resource: resource }
      end

      events.build(new_events)
    end

    def confirm!; end

    def cancel!; end

    def prepare!
      update_attribute(:prepared, true)
    end

    private

    def resource
      Mybookings::Resource.find(resource_id)
    end

    def generate_dates
      until_date = self.until_date.nil? ? start_date : self.until_date

      dates = Array.new

      schedule = IceCube::Schedule.new(start_date)
      schedule.add_recurrence_rule self.send("increment_#{recurrent_type}_until", until_date)

      schedule.each_occurrence do |occurrence|
        dates << occurrence.to_datetime
      end

      dates
    end

    def is_a_recurring_booking?
      (!daily? || (daily? && !until_date.nil?))
    end

    def the_booking_period_is_valid
      return false if until_date.nil? || start_date.nil?
      booking_interval = until_date.to_datetime - start_date.to_datetime
      range_permitted = MYBOOKINGS_CONFIG['maximum_permitted_days_for_recurring_events']
      if  range_permitted.days - booking_interval.days < 0
        errors.add(:until_date, I18n.t('.mybookings.bookings.new.dates_interval_message_error', days_permitted: range_permitted))
      end
    end

    def the_event_duration_is_valid
      return false if end_date.nil? || start_date.nil?
      event_duration_in_seconds = end_date.to_time - start_date.to_time
      permitted_event_duration_in_seconds = MYBOOKINGS_CONFIG['maximum_duration_in_hours_for_an_event'] * 3600
      if event_duration_in_seconds > permitted_event_duration_in_seconds
        errors.add(:end_date, I18n.t('.mybookings.bookings.new.event_duration_message_error', event_duration: MYBOOKINGS_CONFIG['maximum_duration_in_hours_for_an_event']))
      end
    end

    def until_date_in_the_future
      unless until_date.nil?
        errors.add(:until_date, I18n.t('errors.messages.booking.until_date_in_the_past')) if until_date.past?
      end
    end

    def events_are_valid
      events.each do |event|
        next if event.valid?
        event.errors.full_messages.each do |msg|
          errors.add(:base, "#{I18n.t('errors.messages.booking.event_not_valid')} #{msg}")
        end
      end
    end

    def increment_daily_until date
      IceCube::Rule.daily.until(date.end_of_day)
    end

    def increment_weekly_until date
      IceCube::Rule.weekly.until(date.end_of_day)
    end

    def increment_monthly_until date
      IceCube::Rule.monthly.until(date.end_of_day)
    end

    def string_format date
      date.strftime("%d-%m-%Y %H:%M")
    end
  end
end

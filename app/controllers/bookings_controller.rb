class BookingsController < BaseController
  before_action :load_booking, only: [:destroy, :edit_feedback, :set_feedback]

  def index
    load_current_user_bookings
  end

  def new_first_step
    @resource_types = ResourceType.all
  end

  def new_second_step
    resource_type = ResourceType.find(params[:booking_id])
    load_available_resources_by_resource_type resource_type
    @booking = Booking.new(resource_type: resource_type)
    @booking.events.build
  end

  def create
    @booking = Booking.new_for_user(current_user, booking_params)

    if @booking.valid?
      @booking.events.each do |event|
        ResourceTypesExtensionsWrapper.call(:after_booking_creation, event)
      end
      @booking.save!
      NotificationsMailer.notify_new_booking(@booking).deliver_now!
      return redirect_to bookings_path
    else
      load_available_resources_by_resource_type resource_type @booking.resource_type
      render 'new'
    end
  end

  def destroy
    if @booking.has_pending_events?
      NotificationsMailer.notify_delete_booking(@booking).deliver!
      @booking.delete_pending_events
      @booking.destroy unless @booking.has_events?
    end
    redirect_to bookings_path
  end

  def edit_feedback; end

  def set_feedback
    @booking.feedback = params[:booking][:feedback]
    @booking.save!

    redirect_to bookings_path, notice: I18n.t('bookings.index.feedback_received')
  end

  private

  def booking_params
    params.require(:booking).permit!
  end

  def load_available_resources_by_resource_type resource_type
    @resources = Resource.available_by_resource_type resource_type
  end

  def load_booking
    booking_id = params[:id] || params[:booking_id]

    @booking = BookingDecorator.find(booking_id)
    authorize @booking
  end

  def load_current_user_bookings
    @bookings = policy_scope(Booking).by_start_date.map { |resource_type, bookings| [resource_type,
      BookingDecorator.decorate_collection(bookings)] }
  end
end

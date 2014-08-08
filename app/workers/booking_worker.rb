require 'nokogiri'

# The BookingWorker performs the tasks needed in order to provision services
# to fulfill client bookings.
#
# These are dependent on the booking information in the services. Therefore,
# the BookingWorker contains methods named after the booking types and actions,
# e.g.: book_immediate_booking(booking) or cancel_synchronous_booking(booking).
class BookingWorker
  @queue = :booking

  class << self
    include Rails.application.routes.url_helpers
  end

  def self.perform(host, booking_id, action)
    # This would introduce a concurrency issue, if some bookings
    # would originate from requests to different HTTP hosts.
    Rails.application.routes.default_url_options[:host] = host

    booking = ServiceBooking.find(booking_id)

    begin
      service = booking.service

      SDL::Base::Type::Booking.subtypes.map(&:local_name).map(&:underscore).each do |type|
        if service.send(type)
          send("#{action}_#{type}", booking)

          notify_callback_url(booking) if booking.callback_url
        end
      end
    rescue Exception => e
      if booking.booking?
        booking.booking_status = :booking_failed
      else
        booking.booking_status = :canceling_failed
      end

      booking.send("#{booking.booking_status}_time=", Time.new)
      booking.failed_reason = e.message
    end
  end

  def self.book_immediate_booking(booking)
    booking.update_attributes!(
        endpoint_url: booking.service.immediate_booking.endpoint_url.value,
        booking_status: :booked,
        booked_time: Time.new
    )
  end

  def self.cancel_immediate_booking(booking)
    booking.update_attributes!(
        booking_status: :canceled,
        canceled_time: Time.new
    )
  end

  def self.notify_callback_url(booking)
    booking_xml = ::Nokogiri::XML::Builder.new do |xml|
      eval(File.read(File.expand_path('../views/bookings/_booking.xml.nokogiri', File.dirname(__FILE__))), binding)
    end.to_xml

    begin
      uri = URI(booking.callback_url)

      Net::HTTP.start(uri.host, uri.port) do |http|
        http.request_post(uri.path.blank? ? '/' : uri.path, booking_xml, {'Content-Type' => 'application/xml'})
      end
    rescue Exception => e
      # We don't handle exceptions in callback URL notifications
      puts e
    end
  end
end
class EventsController < ApplicationController

  def index
  end

  def create
    begin
      event = Event.new(params[:event])
      Broker.new('events').publish(event)

      msg = 'OK'
      flash[:notice] = msg
    rescue StandardError => e
      msg = "#{e} #{e.backtrace[0..7].join("\n")}"
      flash[:alert] = msg
    end

    request.referer ? redirect_to(:back) : render(plain: msg)

  end
end
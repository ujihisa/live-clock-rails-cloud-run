require 'async/websocket/adapters/rails'

class ClockTag < Live::View
  def bind(page)
    super # @page = page

    # Schedule a refresh every second:
    Async do
      while @page
        update!
        sleep 1
      end
    end
  end

  def render(builder)
    builder.tag('div') do
      builder.text(Time.now.to_s)
    end
  end
end

class ClockController < ApplicationController
  RESOLVER = Live::Resolver.allow(ClockTag)

  def index
    @tag = ClockTag.new('flappy')
  end

  skip_before_action :verify_authenticity_token, only: :live

  def live
    self.response = Async::WebSocket::Adapters::Rails.open(request) do |connection|
      Live::Page.new(RESOLVER).run(connection)
    end
  end
end

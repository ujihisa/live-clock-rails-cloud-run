require 'async/websocket/adapters/rails'

class CookieTag < Live::View
  @@font_scale = 1
  @@events = []

  def initialize(...)
    super(...)
  end

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
    # builder.tag('div', onclick: forward_event) do
      builder.append(<<~"EOF")
      <font style="font-size: #{(@@font_scale * 100).to_i}%;">
        #{Time.now}
      </font>
      #{
        @@events.map {|event|
          <<~EOF
          <div style="background-color: red; position: absolute; left: #{event[:clientX] - 5}px; top: #{event[:clientY] - 5}px; width: 10px; height: 10px;">
          </div>
          EOF
        }.join
      }
      EOF
  end

  def handle(event)
    pp event
    case event[:type]
    when 'click'
      @@font_scale += 0.1
      @@events << event
      update!
    end
  end
end

class CookieController < ApplicationController
  RESOLVER = Live::Resolver.allow(CookieTag)

  def index
    @tag = CookieTag.new('cookie')
  end

  skip_before_action :verify_authenticity_token, only: :live

  def live
    self.response = Async::WebSocket::Adapters::Rails.open(request) do |connection|
      Live::Page.new(RESOLVER).run(connection)
    end
  end
end

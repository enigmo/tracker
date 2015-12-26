module Tracker
  module Entities
    module Events #:nodoc:
      class <<self
        def reset!
          @events = {}
        end

        def events
          @events ||= {}
        end

        def register(name, event_class)
          events[name] = event_class
        end

        def event_names
          events.keys
        end

        def infer_event_class(underscore)
          event_name = event_names.find { |event| event == underscore.to_s }
          events[event_name]
        end
      end

      class Event #:nodoc:
        include Virtus.model

        attribute :event_type

        def self.parse(values)
          new(values)
        end
      end

      class Pageview < Event #:nodoc:
      end

      class Click < Event #:nodoc:
        attribute :event_type, String, default: 'click'
        attribute :label
      end

      Events.register('pageview', Click)
      Events.register('click', Click)
    end

    class Client #:nodoc:
      include Virtus.model

      attribute :ip
      attribute :tracking_id
      # raw user_agent string
      attribute :user_agent

      # detected browser info
      attribute :name
      attribute :version
      attribute :full_version
      attribute :platform
      attribute :device
      attribute :bot_name

      attribute :location

      attribute :td_fields

      def initialize(attrs = {})
        super(attrs)
        detect_browser!
      end

      # rubocop:disable Metrics/MethodLength
      def detect_browser!
        browser = Browser.new(ua: user_agent)
        self.attributes = {
          name: browser.name,
          version: browser.version,
          full_version: browser.full_version,
          platform: browser.platform,
          device: device_name(browser),
          bot_name: browser.bot_name
        }
      end
      # rubocop:enable Metrics/MethodLength

      def device_name(browser)
        case
        when browser.tablet? then 'Tablet'
        when browser.mobile? then 'Mobile'
        when (browser.bot? || browser.search_engine?) then  'Bot'
        when browser.platform != :other then 'PC'
        else 'Unknown'
        end
      end
    end

    class Record #:nodoc:
      include Virtus.model

      attribute :event
      attribute :client

      # rubocop:disable Metrics/MethodLength
      # rubocop:disable Metrics/AbcSize
      def as_json(options = {})
        {
          ip: client.ip,
          tracking_id: client.tracking_id,
          id: client.td_fields[:td_client_id],
          user_agent: client.user_agent,
          name: client.name,
          version: client.version,
          platform: client.platform,
          device: client.device,
          bot_name: client.bot_name,
          location: client.location,
          referer: client.td_fields[:td_referrer],
          title: client.td_fields[:td_title],
          url: client.td_fields[:td_url],
          path: client.td_fields[:td_path]
        }.merge(event.as_json(options))
      end
      # rubocop:enable Metrics/MethodLength
      # rubocop:enable Metrics/AbcSize
    end
  end
end

require 'grape'
require 'browser'
require 'rack/contrib'
require 'virtus'
require 'active_support'
require 'active_support/core_ext'

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
      # raw user_agent string
      attribute :user_agent
      # detected browser info
      attribute :browser
      attribute :location

      def initialize(attrs = {})
        super(attrs)
        detect_browser!
      end

      def detect_browser!
        self.browser = Browser.new(ua: user_agent)
      end
    end

    class Record
      include Virtus.model

      attribute :td_fields
      attribute :event

      def as_json(options={})
        td_fields.merge(event.attributes)
      end
    end
  end

  class API < Grape::API #:nodoc:
    helpers do
      def logger
        API.logger
      end

      def remote_ip
        # This assumes that the app is mounted on Rails
        env['action_dispatch.remote_ip'].to_s
      end

      def akamai_client_ip
        request.headers['HTTP_TRUE_CLIENT_IP']
      end

      def akamai_edgescape
        request.headers['akamai.edgescape']
      end

      def client
        @client ||= Entities::Client.new(
          user_agent: request.user_agent,
          ip: akamai_client_ip || remote_ip,
          location: akamai_edgescape
        )
      end

      def request_params
        declared(params)
      end

      def td_fields
        request_params[:data].select { |k, _v| k.starts_with?('td') }
      end

      params :td_fields do
        optional :td_version
        requires :td_client_id
        optional :td_charset
        optional :td_language
        optional :td_color
        optional :td_screen
        optional :td_viewport
        optional :td_title
        requires :td_url
        optional :td_host
        optional :td_path
        optional :td_referrer
        optional :td_ip
        optional :td_browser
        optional :td_browser_version
        optional :td_os
        optional :td_os_version
      end
    end

    use Rack::JSONP
    default_format :json

    desc 'track pageview'
    params do
      requires :modified, type: Integer
      requires :data,
               type: Hash,
               coerce_with: ->(c) { MultiJson.load(Base64.decode64(c)) } do
                 use :td_fields
                 optional :tracking_id
               end
      optional :callback, type: String
    end

    get :pageview do
      event_class = Entities::Events.infer_event_class('pageview')
      record = Entities::Record.new(td_fields: td_fields, event: event_class.parse(request_params[:data]))
      logger.info(record.to_json)
      request_params[:callback] ? request_params[:callback] : 'tracked'
    end

    desc 'track event'
    params do
      requires :modified, type: Integer
      requires :data,
               type: Hash,
               coerce_with: ->(c) { MultiJson.load(Base64.decode64(c)) } do
                 use :td_fields
                 optional :tracking_id
               end
      optional :callback, type: String
      # path params(see below)
      requires :event_type, type: String, values: Entities::Events.event_names
    end

    # ugly hack to circumvent td-js-sdk request
    # url generation(trackEvent(:table) => /:path/:database/:table))
    get 'event_:event_type' do
      event_class = Entities::Events.infer_event_class(request_params[:event_type])
      record = Entities::Record.new(td_fields: td_fields, event: event_class.parse(request_params[:data]))
      logger.info(record.to_json)
      request_params[:callback] ? request_params[:callback] : 'tracked'
    end
  end
end

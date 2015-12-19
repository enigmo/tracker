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

      class Click
      end
      Events.register('click', Click)
    end

    class Client #:nodoc:
      include Virtus.model

      attribute :ip
      # raw user_agent string
      attribute :user_agent
      # detected browser info
      attribute :browser

      def initialize(attrs = {})
        super(attrs)
        detect_browser!
      end

      def detect_browser!
        self.browser = Browser.new(ua: user_agent)
      end
    end
  end

  class API < Grape::API #:nodoc:
    helpers do
      def logger
        API.logger
      end

      def client
        @client ||= Entities::Client.new(
          user_agent: request.user_agent
        )
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
               end
      optional :callback, type: String
    end

    get :pageview do
      request_params = declared(params)
      logger.info(request_params)
      logger.info(client)
      request_params[:callback] ? request_params[:callback] : 'tracked'
    end

    desc 'track event'
    params do
      requires :modified, type: Integer
      requires :data,
               type: Hash,
               coerce_with: ->(c) { MultiJson.load(Base64.decode64(c)) } do
                 use :td_fields
               end
      optional :callback, type: String
      requires :event_type, type: String
    end

    # ugly hack to circumvent td-js-sdk request
    # url generation(trackEvent(:table) => /:path/:database/:table))
    get 'event_:event_type' do
      request_params = declared(params)
      logger.info(client)
      logger.info(request_params)
      logger.info(params)

      event = Entities::Events.infer_event_class(request_params[:event_type])

      request_params[:callback] ? request_params[:callback] : 'tracked'
    end
  end
end

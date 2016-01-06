require 'grape'
require 'browser'
require 'rack/contrib'
require 'virtus'
require 'active_support'
require 'active_support/core_ext'

require 'tracker/entities'

module Tracker
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
          tracking_id: tracking_id,
          location: akamai_edgescape,
          td_fields: td_fields
        )
      end

      def request_params
        declared(params)
      end

      def td_fields
        Hashie::Mash.new(
          request_params[:data].select { |k, _v| k.starts_with?('td') }
        )
      end

      def tracking_id
        request_params[:data][:tracking_id]
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

    # This, combined with :event_type requirement above, 
    # captures all the path predefined(like /pageview or /click)
    get '*event_type' do
      event_class = Entities::Events.infer_event_class(request_params[:event_type])
      record = Entities::Record.new(client: client, event: event_class.parse(request_params[:data]))
      logger.info(record.to_json)
      request_params[:callback] ? request_params[:callback] : 'tracked'
    end
  end
end

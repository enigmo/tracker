require 'grape'
require 'browser'
require 'rack/contrib'

module Tracker
  class API < Grape::API #:nodoc:
    helpers do
      def logger
        API.logger
      end
    end

    use Rack::JSONP
    default_format :json

    params do
      requires :modified, type: Integer
      requires :data,
               type: Hash,
               coerce_with: ->(c) { MultiJson.load(Base64.decode64(c)) }
      optional :callback, type: String
    end

    desc 'track event'
    get :event do
      'tracked'
    end

    params do
      requires :modified, type: Integer
      requires :data,
               type: Hash,
               coerce_with: ->(c) { MultiJson.load(Base64.decode64(c)) }
      optional :callback, type: String
    end

    desc 'track pageview'
    get :pageview do
      logger.info(params)
      'TreasureJSONPCallback0'
    end
  end
end

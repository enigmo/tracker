require 'grape'

module Tracker
  class API < Grape::API #:nodoc:
    resource :event do
      desc 'track event'
      get :track do
        'tracked'
      end
    end
  end
end

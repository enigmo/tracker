require 'spec_helper'

describe Tracker do
  include Rack::Test::Methods

  def app
    Tracker::API.new
  end

  it 'should do something' do
    get '/event/track'
    expect(last_response.body).to eq 'tracked'
  end
end

require 'spec_helper'

describe Tracker do
  include Rack::Test::Methods

  def app
    Tracker::API.logger(logger)
    Tracker::API.new
  end

  let :logger do
    Logger.new('/dev/null')
  end

  before :each do
    header 'User-Agent', 'Firefox'
  end

  describe 'page view' do
    let :request_url do
      '/pageview?' +
        { api_key: '',
          modified: '1450434122941',
          data: encoded_data,
          callback: 'TreasureJSONPCallback0'
        }.to_query
    end

    let :encoded_data do
      Base64.encode64({
        td_url: 'https://example.com/',
        td_client_id: SecureRandom.uuid
      }.to_json)
    end

    let :response_jsonp do
      '/**/TreasureJSONPCallback0("TreasureJSONPCallback0")'
    end

    it 'should do something' do
      get request_url

      expect(last_response.body).to eq response_jsonp
    end
  end

  describe 'event' do
    let :request_url do
      '/click?' +
        { api_key: '',
          modified: '1450434122941',
          data: encoded_data,
          callback: 'TreasureJSONPCallback0'
        }.to_query
    end

    let :encoded_data do
      Base64.encode64({
        td_url: 'https://example.com/',
        td_client_id: SecureRandom.uuid
      }.to_json)
    end

    let :response_jsonp do
      '/**/TreasureJSONPCallback0("TreasureJSONPCallback0")'
    end

    it 'should decode base64 encoded data' do
      expect(logger).to receive(:info) do |record_json|
        record = JSON.load(record_json)

        expect(record['url']).to eq 'https://example.com/'
      end

      get request_url
      expect(last_response.body).to eq response_jsonp
    end
  end
end

require 'spec_helper'

describe Tracker do
  include Rack::Test::Methods

  def app
    Tracker::API.new
  end

  it 'should do something' do
    get '/event'
    expect(last_response.body).to eq 'tracked'.to_json
  end

  describe 'page view' do
    let :request_url do
      '/pageview?api_key=&modified=1450434122941&data=eyJ0ZF92ZXJzaW9uIjoiMS41LjEiLCJ0ZF9jbGllbnRfaWQiOiJkZmU0YTlmZC00YWEzLTQxZGUtZDVmMi04MDdhZjY1ZTI1ZmMiLCJ0ZF9jaGFyc2V0IjoidXRmLTgiLCJ0ZF9sYW5ndWFnZSI6ImphIiwidGRfY29sb3IiOiIyNC1iaXQiLCJ0ZF9zY3JlZW4iOiIxNDQweDkwMCIsInRkX3ZpZXdwb3J0IjoiNzQ5eDc4MiIsInRkX3RpdGxlIjoiQSBuZXcgb25saW5lIHBlcnNvbmFsIHNob3BwaW5nIGV4cGVyaWVuY2UgLSBCVVlNQSBmcm9tIEphcGFuIiwidGRfdXJsIjoiaHR0cHM6Ly9sb2NhbC5idXltYS51cy8iLCJ0ZF9ob3N0IjoibG9jYWwuYnV5bWEudXMiLCJ0ZF9wYXRoIjoiLyIsInRkX3JlZmVycmVyIjoiIiwidGRfaXAiOiJ0ZF9pcCIsInRkX2Jyb3dzZXIiOiJ0ZF9icm93c2VyIiwidGRfYnJvd3Nlcl92ZXJzaW9uIjoidGRfYnJvd3Nlcl92ZXJzaW9uIiwidGRfb3MiOiJ0ZF9vcyIsInRkX29zX3ZlcnNpb24iOiJ0ZF9vc192ZXJzaW9uIn0%3D&callback=TreasureJSONPCallback0'
    end

    let :encoded_data do
    end

    let :response_jsonp do
      '/**/TreasureJSONPCallback0("TreasureJSONPCallback0")'
    end

    it 'should decode base64 encoded data' do
      get request_url
      expect(last_response.body).to eq response_jsonp
    end
  end
end

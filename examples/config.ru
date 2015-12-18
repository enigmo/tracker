require 'tracker'

use Rack::Static, url: [''], root: 'public', index: 'index.html'
run Rack::URLMap.new('/tracker' => Tracker::API)

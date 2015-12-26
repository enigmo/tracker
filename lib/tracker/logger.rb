module Tracker
  class Logger < ::Logger #:nodoc:
    def initialize(logdev, shift_age = 0, shift_size = 1_048_576)
      super(logdev, shift_age, shift_size)
      self.formatter = ->(_severity, _datetime, _progname, message) { message }
    end
  end
end

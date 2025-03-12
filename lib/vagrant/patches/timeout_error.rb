# Adds an IO::TimeoutError for versions of ruby where it isn't defined (< 3.2). 
if !defined?(IO::TimeoutError)
  class IO::TimeoutError < StandardError
  end
end
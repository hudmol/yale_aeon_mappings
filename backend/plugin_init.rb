begin
  SystemStatus.group('Yale Aeon', ['Yale Aeon Last Request', 'Yale Aeon Errors'])
  SystemStatus.update('Yale Aeon Last Request', :no, 'Waiting for first request ...')
  SystemStatus.update('Yale Aeon Errors', :good, 'No errors reported')
rescue => e
  Log.error "Problem with SystemStatus: " + e.message
end


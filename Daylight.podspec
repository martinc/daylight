Pod::Spec.new do |s|
  s.name             = 'Daylight'
  s.version          = '0.1.0'
  s.summary          = 'A swift package that provides NOAA astronomical algorithms for times for sunrise, sunset, dawn, dusk, and noon'
  s.description      = <<-DESC
Daylight is a swift package that provides methods to generate the times of solar events in a given location on a given calendar date.
These solar events include sunrise, sunset, noon, civil dawn and dusk, nautical dawn and dusk, and astronomical dawn and dusk.
It provides algorithms used by NOAA.
                       DESC
  s.homepage         = 'https://github.com/martinc/daylight'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Martin Ceperley' => 'martin@ceperley.com' }
  s.source           = { :git => 'https://github.com/martinc/daylight.git', :tag => s.version.to_s }
  s.ios.deployment_target = '8.0'
  s.source_files = 'Sources/*'
end

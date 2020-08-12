platform :ios, '9.0'

workspace 'PayPal.xcworkspace'
inhibit_all_warnings!

target 'Demo' do
  pod 'PayPal', :path => './'
  pod 'Braintree'
  pod 'InAppSettingsKit'
end

abstract_target 'Tests' do
  pod 'PayPal', :path => './'
  pod 'Braintree'

  target 'UnitTests'
  target 'IntegrationTests'
end

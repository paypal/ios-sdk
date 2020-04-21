platform :ios, '9.0'

workspace 'PayPalCommercePlatform.xcworkspace'
inhibit_all_warnings!

target 'Demo' do
  pod 'PayPalCommercePlatform', :path => './'
  pod 'Braintree', '~> 4.33'
  pod 'InAppSettingsKit'
end

abstract_target 'Tests' do
  pod 'PayPalCommercePlatform', :path => './'
  pod 'Braintree', '~> 4.33'

  target 'UnitTests'
  target 'IntegrationTests'
end

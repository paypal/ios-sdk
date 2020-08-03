platform :ios, '9.0'

workspace 'PayPal.xcworkspace'
inhibit_all_warnings!

target 'Demo' do
  pod 'PayPal', :path => './'
  pod 'Braintree', :git => 'https://github.com/braintree/braintree_ios.git', :branch => 'fpti-and-id-token-support'
  pod 'InAppSettingsKit'
end

abstract_target 'Tests' do
  pod 'PayPal', :path => './'
  pod 'Braintree', :git => 'https://github.com/braintree/braintree_ios.git', :branch => 'fpti-and-id-token-support'

  target 'UnitTests'
  target 'IntegrationTests'
end

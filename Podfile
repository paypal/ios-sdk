platform :ios, '9.0'

workspace 'PayPal.xcworkspace'
inhibit_all_warnings!

target 'Demo' do
  pod 'PayPal', :path => './'
  pod 'Braintree', :git => 'https://github.com/braintree/braintree_ios.git', :branch => 'pp-fpti'
  pod 'InAppSettingsKit'
end

abstract_target 'Tests' do
  pod 'PayPal', :path => './'
  pod 'Braintree', :git => 'https://github.com/braintree/braintree_ios.git', :branch => 'pp-fpti'

  target 'UnitTests'
  target 'IntegrationTests'
end

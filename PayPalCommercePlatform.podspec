Pod::Spec.new do |s|
  s.name             = "PayPalCommercePlatform"
  s.version          = "0.0.1"
  s.summary          = "The PayPal Commerce Platform SDK is a limited-release solution only available to select merchants and partners."
  s.description      = <<-DESC
                          The PayPal Commerce Platform SDK enables you to accept payments in your native mobile app.
                          This native SDK leverages the client-side SDK in conjunction with PayPal's v2 Orders API for seamless and faster mobile optimization.
  DESC
  s.homepage         = "https://developer.paypal.com/docs/limited-release/ppcp-sdk/"
  s.documentation_url = "https://developer.paypal.com/docs/limited-release/ppcp-sdk/"
  s.author           = { "Braintree" => "code@getbraintree.com" }
  s.source           = { :git => "https://github.com/braintree/paypal-commerce-platform-ios.git", :tag => s.version.to_s }

  s.platform         = :ios, "9.0"
  s.requires_arc     = true
  s.compiler_flags = "-Wall -Werror -Wextra"

  s.source_files  = "PayPalCommercePlatform/**/*.{h,m}"
  s.public_header_files = "PayPalCommercePlatform/Public/*.h"

  s.dependency "Braintree"
  s.dependency "Braintree/Apple-Pay"
  s.dependency "Braintree/PaymentFlow"
end

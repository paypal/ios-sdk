Pod::Spec.new do |s|
  s.name             = "PayPal"
  s.version          = "0.0.1"
  s.summary          = "The PayPal iOS SDK is a limited-release solution only available to select merchants and partners."
  s.description      = <<-DESC
                          The PayPal iOS SDK enables you to accept payments in your native mobile app.
                          This native SDK leverages the client-side SDK in conjunction with PayPal's v2 Orders API for seamless and faster mobile optimization.
  DESC
  s.homepage         = "https://developer.paypal.com/docs/limited-release/ppcp-sdk/"
  s.documentation_url = "https://developer.paypal.com/docs/limited-release/ppcp-sdk/"
  s.author           = { "Braintree" => "code@getbraintree.com" }
  s.source           = { :git => "https://github.com/paypal/iOS-SDK.git", :tag => s.version.to_s }

  s.platform         = :ios, "9.0"
  s.requires_arc     = true
  s.compiler_flags = "-Wall -Werror -Wextra"

  s.source_files  = "PayPal/**/*.{h,m}"
  s.public_header_files = "PayPal/Public/*.h"

  s.dependency "Braintree", "~> 4.35"
  s.dependency "Braintree/Apple-Pay", "~> 4.35"
  s.dependency "Braintree/PaymentFlow", "~> 4.35"
  s.vendored_frameworks = "Frameworks/FPTI.framework"
end

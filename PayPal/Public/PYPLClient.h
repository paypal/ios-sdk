#import <PassKit/PassKit.h>

#if __has_include("BraintreeCard.h")
#import "BraintreeCard.h"
#else
#import <BraintreeCard/BraintreeCard.h>
#endif

#if __has_include("BraintreeApplePay.h")
#import "BraintreeApplePay.h"
#else
#import <BraintreeApplePay/BraintreeApplePay.h>
#endif

#if __has_include("BraintreePaymentFlow.h")
#import "BraintreePaymentFlow.h"
#else
#import <BraintreePaymentFlow/BraintreePaymentFlow.h>
#endif

#if __has_include("PayPalDataCollector.h")
#import "PPDataCollector.h"
#else
#import <PayPalDataCollector/PPDataCollector.h>
#endif

#import "PYPLApplePayCheckoutResult.h"
#import "PYPLCardCheckoutResult.h"
#import "PYPLPayPalCheckoutResult.h"

NS_ASSUME_NONNULL_BEGIN

/**
 Error domain for PYPLClient errors.
 */
FOUNDATION_EXPORT NSString * const PYPLClientErrorDomain;

/**
 This class acts as the entry point for processing Apple Pay, Card, and PayPal payments.
 */
@interface PYPLClient : NSObject

/**
 Completion block for the SDK to recieve the result of the Apple Pay order authorization or capture.
*/
typedef void (^PYPLApplePayResultHandler)(BOOL success);

/**
 A required delegate to control the presentation and dismissal of view controllers.
 */
@property (nonatomic, weak) id<BTViewControllerPresentingDelegate> presentingDelegate;

/**
 Initializes a new `PYPLClient`.

 @param idToken A valid PayPal ID Token.
 @return A PYPLClient, or `nil` if initialization failed.
 */
- (nullable instancetype)initWithIDToken:(NSString *)idToken;

/**
 @brief Initiates the Card checkout flow.

 @discussion Processes the card payment utilizing the 3D Secure verification authorization flow. If a 3DS challenge is required, the user is redirected to a `SFSafariViewController` to enter their pin to complete the challenge. If no 3DS challenge is present, no additional action is required by the user and the completion is called with result information.

 @param orderId A valid PayPal orderID.
 @param card A `BTCard` object that contains customer's card details.
 @param completion Callback that returns a `PYPLCardCheckoutResult` on successful checkout or an `error` if a failure occured.
 */
- (void)checkoutWithCard:(NSString *)orderId
                    card:(BTCard *)card
              completion:(void (^)(PYPLCardCheckoutResult * _Nullable result, NSError * _Nullable error))completion NS_SWIFT_NAME(checkoutWithCard(orderID:card:completion:));

/**
 @brief Initiates the Pay with PayPal checkout flow.

 @discussion Redirects user to a `SFSafariViewController` to login with their PayPal account to complete a PayPal checkout.

 @param orderId A valid PayPal orderID.
 @param completion Callback that returns a `PYPLPayPalCheckoutResult` on successful checkout or an `error` if a failure occured.
 */
- (void)checkoutWithPayPal:(NSString *)orderId
                completion:(void (^)(PYPLPayPalCheckoutResult * _Nullable result, NSError * _Nullable error))completion NS_SWIFT_NAME(checkoutWithPayPal(orderID:completion:));

/**
 @brief Initiates an Apple Pay checkout flow.

 @discussion Presents a `PKPaymentAuthorizationViewController` to the user to complete an Apple Pay checkout flow. The required `BTViewControllerPresentingDelegate` protocol methods will be called upon UI presentation and dismissal.

 You must call the `PYPLApplePayResultHandler` with a boolean to indicate the success or failure of your payment authorization or capture. This is so the SDK can notify the user of the payment's status.

 @param orderId A valid PayPal orderID.
 @param paymentRequest A valid `PKPaymentRequest`.
 @param completion Callback that returns a `PYPLApplePayCheckoutResult` on successful checkout or an `error` if a failure occured.
 */
- (void)checkoutWithApplePay:(NSString *)orderId
              paymentRequest:(PKPaymentRequest *)paymentRequest
                  completion:(void (^)(PYPLApplePayCheckoutResult * _Nullable result, NSError * _Nullable error, _Nullable PYPLApplePayResultHandler resultHandler))completion NS_SWIFT_NAME(checkoutWithApplePay(orderID:paymentRequest:completion:));

@end

NS_ASSUME_NONNULL_END

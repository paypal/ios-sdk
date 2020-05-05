#import <PassKit/PassKit.h>
#import "PYPLCheckoutResult.h"

NS_ASSUME_NONNULL_BEGIN

/**
The result of a successful Apple Pay checkout flow
*/
@interface PYPLApplePayCheckoutResult : PYPLCheckoutResult

/**
The user-selected billing address for this transaction.
*/
@property (nullable, readonly, nonatomic, strong) PKContact *billingContact;

/**
The user-selected shipping address for this transaction.
*/
@property (nullable, readonly, nonatomic, strong) PKContact *shippingContact;

/**
The user-selected shipping method for this transaction.
*/
@property (nullable, readonly, nonatomic, strong) PKShippingMethod *shippingMethod;

/**
Initializes result of a successful checkout flow with the associated Order ID.

@param orderID A valid PayPal Order ID.
@param payment A `PKPayment` instance, obtained from the presented `PKPaymentAuthorizationViewController`
@return A PYPLApplePayCheckoutResult instance.
*/
- (instancetype)initWithOrderID:(NSString *)orderID payment:(PKPayment *)payment NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END

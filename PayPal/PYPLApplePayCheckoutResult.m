#import "PYPLApplePayCheckoutResult.h"

@implementation PYPLApplePayCheckoutResult

- (instancetype)initWithOrderID:(NSString *)orderID payment:(PKPayment *)payment {
    self = [super initWithOrderID:[orderID copy]];
    if (self) {
        _shippingMethod = payment.shippingMethod;
        _shippingContact = payment.shippingContact;
        _billingContact = payment.billingContact;
    }
    return self;
}


@end

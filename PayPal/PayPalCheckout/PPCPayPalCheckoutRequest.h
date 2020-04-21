#if __has_include("BraintreePaymentFlow.h")
#import "BraintreePaymentFlow.h"
#else
#import <BraintreePaymentFlow/BraintreePaymentFlow.h>
#endif

NS_ASSUME_NONNULL_BEGIN

@interface PPCPayPalCheckoutRequest : BTPaymentFlowRequest <BTPaymentFlowRequestDelegate>

@property (readonly, nonatomic) NSURL *checkoutURL;

- (instancetype)initWithCheckoutURL:(NSURL *)checkoutURL;

@end

NS_ASSUME_NONNULL_END

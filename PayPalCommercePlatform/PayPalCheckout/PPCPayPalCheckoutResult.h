#if __has_include("BraintreePaymentFlow.h")
#import "BraintreePaymentFlow.h"
#else
#import <BraintreePaymentFlow/BraintreePaymentFlow.h>
#endif

NS_ASSUME_NONNULL_BEGIN

@interface PPCPayPalCheckoutResult : BTPaymentFlowResult

@property (copy, nonatomic) NSString *payerID;
@property (copy, nonatomic) NSString *token;

- (instancetype)initWithURL:(NSURL *)url;

@end

NS_ASSUME_NONNULL_END

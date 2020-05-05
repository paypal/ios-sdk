#if __has_include("BraintreePaymentFlow.h")
#import "BraintreePaymentFlow.h"
#else
#import <BraintreePaymentFlow/BraintreePaymentFlow.h>
#endif

NS_ASSUME_NONNULL_BEGIN

@interface PYPLCardContingencyRequest : BTPaymentFlowRequest <BTPaymentFlowRequestDelegate>

@property (readonly, nonatomic) NSURL *contingencyURL;

- (instancetype)initWithContingencyURL:(NSURL *)contingencyURL;

@end

NS_ASSUME_NONNULL_END

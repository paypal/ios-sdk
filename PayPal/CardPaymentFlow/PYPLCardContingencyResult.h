#if __has_include("BraintreePaymentFlow.h")
#import "BraintreePaymentFlow.h"
#else
#import <BraintreePaymentFlow/BraintreePaymentFlow.h>
#endif

NS_ASSUME_NONNULL_BEGIN

@interface PYPLCardContingencyResult : BTPaymentFlowResult

@property (copy, nonatomic) NSString *state;
@property (copy, nonatomic) NSString *code;
@property (copy, nonatomic, nullable) NSString *error;
@property (copy, nonatomic, nullable) NSString *errorDescription;

- (instancetype)initWithURL:(NSURL *)url;

@end

NS_ASSUME_NONNULL_END

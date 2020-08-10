#if __has_include("BraintreeCore.h")
#import "BraintreeCore.h"
#else
#import <BraintreeCore/BraintreeCore.h>
#endif

NS_ASSUME_NONNULL_BEGIN

@interface BTAPIClient (Analytics)

- (void)sendAnalyticsEvent:(NSString *)eventName;

@end

NS_ASSUME_NONNULL_END

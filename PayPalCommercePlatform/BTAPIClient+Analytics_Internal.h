#if __has_include("BraintreeCore.h")
#import "BraintreeCore.h"
#else
#import <BraintreeCore/BraintreeCore.h>
#endif

@interface BTAPIClient (Analytics)

- (void)sendAnalyticsEvent:(NSString *)eventName;

@end

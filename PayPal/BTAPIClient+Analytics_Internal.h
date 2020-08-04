#if __has_include("BraintreeCore.h")
#import "BraintreeCore.h"
#else
#import <BraintreeCore/BraintreeCore.h>
#endif

NS_ASSUME_NONNULL_BEGIN

@interface BTAPIClient (Analytics)

@property (nonatomic, readonly, assign) BOOL isFPTIAvailable;

- (void)sendSDKEvent:(NSString *)eventName with:(NSDictionary *)additionalData;

@end

NS_ASSUME_NONNULL_END

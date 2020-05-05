#import <Foundation/Foundation.h>

#if __has_include("BraintreeCore.h")
#import "BraintreeCore.h"
#else
#import <BraintreeCore/BraintreeCore.h>
#endif

NS_ASSUME_NONNULL_BEGIN

@interface PYPLValidationResult : NSObject

@property (nonatomic, readonly, nullable) NSURL *contingencyURL;

@property (nonatomic, copy) NSString *issueType;

@property (nonatomic, copy) NSString *message;

- (instancetype)initWithJSON:(BTJSON *)JSON;

@end

NS_ASSUME_NONNULL_END

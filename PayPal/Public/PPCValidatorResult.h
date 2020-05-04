#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 The result of a successful checkout flow
 */
@interface PPCValidatorResult : NSObject

/**
 Order ID associated with the checkout
 */
@property (nonatomic, copy) NSString *orderID;

@end

NS_ASSUME_NONNULL_END

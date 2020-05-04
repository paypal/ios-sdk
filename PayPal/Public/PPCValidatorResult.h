#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 The result of a successful checkout flow
 */
@interface PPCValidatorResult : NSObject

/**
 Order ID associated with the checkout
 */
@property (readonly, nonatomic, copy) NSString *orderID;

/**
 Initializes result of a successful checkout flow with the associated Order ID.
 
 @param orderID A valid PayPal Order ID.
 @return A PPCPaymentDetails instance.
 */
- (instancetype)initWithOrderID:(NSString *)orderID NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END

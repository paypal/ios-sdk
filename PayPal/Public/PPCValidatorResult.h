#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 The result of a succesful checkout flow
 */
@interface PPCValidatorResult : NSObject

/**
 Result type
 */
typedef NS_ENUM(NSInteger, PPCValidatorResultType) {
    /// Card
    PPCValidatorResultTypeCard = 0,

    /// PayPal
    PPCValidatorResultTypePayPal,

    /// ApplePay
    PPCValidatorResultTypeApplePay,
};

/**
 Order ID associated with the checkout
 */
@property (nonatomic, copy) NSString *orderID;

/**
 Payment method type of the checkout
 */
@property (nonatomic, assign) PPCValidatorResultType type;

@end

NS_ASSUME_NONNULL_END

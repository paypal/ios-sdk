#import <PassKit/PassKit.h>
#import "PPCValidatorResult.h"

NS_ASSUME_NONNULL_BEGIN

@interface PPCApplePayValidatorResult : PPCValidatorResult

@property (nonatomic, strong) PKContact *billingContact;

@property (nonatomic, strong) PKContact *shippingContact;

@property (nonatomic, strong) PKShippingMethod *shippingMethod;

@end

NS_ASSUME_NONNULL_END

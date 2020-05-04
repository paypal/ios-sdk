#import <PassKit/PassKit.h>
#import "PPCValidatorResult.h"

NS_ASSUME_NONNULL_BEGIN

@interface PPCApplePayValidatorResult : PPCValidatorResult

@property (nullable, nonatomic, strong) PKContact *billingContact;

@property (nullable, nonatomic, strong) PKContact *shippingContact;

@property (nullable, nonatomic, strong) PKShippingMethod *shippingMethod;

@end

NS_ASSUME_NONNULL_END

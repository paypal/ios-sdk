#import <PassKit/PassKit.h>
#import "PPCValidatorResult.h"

NS_ASSUME_NONNULL_BEGIN

@interface PPCApplePayValidatorResult : PPCValidatorResult

@property (nullable, readonly, nonatomic, strong) PKContact *billingContact;

@property (nullable, readonly, nonatomic, strong) PKContact *shippingContact;

@property (nullable, readonly, nonatomic, strong) PKShippingMethod *shippingMethod;

- (instancetype)initWithOrderID:(NSString *)orderID payment:(PKPayment *)payment NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END

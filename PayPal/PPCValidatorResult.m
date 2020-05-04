#import "PPCValidatorResult.h"

@implementation PPCValidatorResult

- (instancetype)initWithOrderID:(NSString *)orderID {
    self = [super init];
    if (self) {
        _orderID = [orderID copy];
    }
    return self;
}

@end

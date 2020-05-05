#import "PYPLCheckoutResult.h"

@implementation PYPLCheckoutResult

- (instancetype)initWithOrderID:(NSString *)orderID {
    self = [super init];
    if (self) {
        _orderID = [orderID copy];
    }
    return self;
}

@end

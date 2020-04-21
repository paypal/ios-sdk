#import "PPCPayPalCheckoutResult.h"

@implementation PPCPayPalCheckoutResult

- (instancetype)initWithURL:(NSURL *)url {
    self = [super init];
    if (self) {
        NSDictionary *queryDictionary = [BTURLUtils queryParametersForURL:url];
        _payerID = queryDictionary[@"PayerID"];
        _token = queryDictionary[@"token"];
    }

    return self;
}

@end

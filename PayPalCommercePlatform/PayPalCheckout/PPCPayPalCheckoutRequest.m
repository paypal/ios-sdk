#import "PPCPayPalCheckoutRequest.h"
#import "PPCPayPalCheckoutResult.h"

NSString * const PPCPayPalCheckoutRequestErrorDomain = @"com.braintreepayments.PPCPayPalCheckoutRequestErrorDomain";

@interface PPCPayPalCheckoutRequest ()

@property (strong, nonatomic) NSURL *checkoutURL;
@property (nonatomic, weak) id<BTPaymentFlowDriverDelegate> paymentFlowDriverDelegate;

@end

@implementation PPCPayPalCheckoutRequest

- (instancetype)initWithCheckoutURL:(NSURL *)checkoutURL {
    self = [super init];
    if (self) {
        _checkoutURL = checkoutURL;
    }

    return self;
}

- (void)handleRequest:(BTPaymentFlowRequest *)request client:(__unused BTAPIClient *)apiClient paymentDriverDelegate:(id<BTPaymentFlowDriverDelegate>)delegate {
    self.paymentFlowDriverDelegate = delegate;
    PPCPayPalCheckoutRequest *checkoutRequest = (PPCPayPalCheckoutRequest *)request;

    NSString *redirectURLString = [NSString stringWithFormat:@"%@://x-callback-url/braintree/paypal-checkout", [BTAppSwitch sharedInstance].returnURLScheme];
    NSURLQueryItem *redirectQueryItem = [NSURLQueryItem queryItemWithName:@"redirect_uri" value:redirectURLString];
    NSURLQueryItem *nativeXOQueryItem = [NSURLQueryItem queryItemWithName:@"native_xo" value:@"1"];

    NSURLComponents *checkoutURLComponents = [NSURLComponents componentsWithURL:checkoutRequest.checkoutURL resolvingAgainstBaseURL:NO];

    NSMutableArray<NSURLQueryItem *> *queryItems = [checkoutURLComponents.queryItems mutableCopy] ?: [NSMutableArray new];
    [queryItems addObject:redirectQueryItem];
    [queryItems addObject:nativeXOQueryItem];
    checkoutURLComponents.queryItems = queryItems;

    [delegate onPaymentWithURL:checkoutURLComponents.URL error:nil];
}

- (BOOL)canHandleAppSwitchReturnURL:(nonnull NSURL *)url sourceApplication:(__unused NSString *)sourceApplication {
    return [url.host isEqualToString:@"x-callback-url"] && [url.path hasPrefix:@"/braintree/paypal-checkout"];
}

- (void)handleOpenURL:(nonnull NSURL *)url {
    PPCPayPalCheckoutResult *result = [[PPCPayPalCheckoutResult alloc] initWithURL:url];

    if (result.payerID && result.token) {
        [self.paymentFlowDriverDelegate onPaymentComplete:result error:nil];
    } else {
        NSError *error = [NSError errorWithDomain:PPCPayPalCheckoutRequestErrorDomain
                                             code:0
                                         userInfo:@{NSLocalizedDescriptionKey: @"PayPal redirect URL error."}];
        [self.paymentFlowDriverDelegate onPaymentComplete:nil error:error];
    }
}

- (nonnull NSString *)paymentFlowName {
    return @"paypal-commerce-platform-pwpp";
}

@end

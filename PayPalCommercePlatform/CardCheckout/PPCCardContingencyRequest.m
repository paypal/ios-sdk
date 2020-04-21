#import "PPCCardContingencyRequest.h"
#import "PPCCardContingencyResult.h"
#import "PPCValidatorClient.h"

@interface PPCCardContingencyRequest ()

@property (strong, nonatomic) NSURL *contingencyURL;
@property (nonatomic, weak) id<BTPaymentFlowDriverDelegate> paymentFlowDriverDelegate;

@end

@implementation PPCCardContingencyRequest

- (instancetype)initWithContingencyURL:(NSURL *)contingencyURL {
    self = [super init];
    if (self) {
        _contingencyURL = contingencyURL;
    }

    return self;
}

- (void)handleRequest:(BTPaymentFlowRequest *)request client:(__unused BTAPIClient *)apiClient paymentDriverDelegate:(id<BTPaymentFlowDriverDelegate>)delegate {
    self.paymentFlowDriverDelegate = delegate;
    PPCCardContingencyRequest *validateRequest = (PPCCardContingencyRequest *)request;

    NSString *redirectURLString = [NSString stringWithFormat:@"%@://x-callback-url/braintree/paypal-validator", [BTAppSwitch sharedInstance].returnURLScheme];
    NSURLQueryItem *redirectQueryItem = [NSURLQueryItem queryItemWithName:@"redirect_uri" value:redirectURLString];

    NSURLComponents *contingencyURLComponents = [NSURLComponents componentsWithURL:validateRequest.contingencyURL resolvingAgainstBaseURL:NO];
    NSMutableArray<NSURLQueryItem *> *queryItems = [contingencyURLComponents.queryItems mutableCopy] ?: [NSMutableArray new];
    contingencyURLComponents.queryItems = [queryItems arrayByAddingObject:redirectQueryItem];

    [delegate onPaymentWithURL:contingencyURLComponents.URL error:nil];
}

- (BOOL)canHandleAppSwitchReturnURL:(NSURL *)url sourceApplication:(__unused NSString *)sourceApplication {
    return [url.host isEqualToString:@"x-callback-url"] && [url.path hasPrefix:@"/braintree/paypal-validator"];
}

- (void)handleOpenURL:(nonnull NSURL *)url {
    PPCCardContingencyResult *result = [[PPCCardContingencyResult alloc] initWithURL:url];

    if (result.error.length) {
        NSError *validateError = [[NSError alloc] initWithDomain:PPCValidatorErrorDomain
                                                            code:0
                                                        userInfo:@{NSLocalizedDescriptionKey: result.errorDescription ?: @"contingency error"}];

        [self.paymentFlowDriverDelegate onPaymentComplete:nil error:validateError];
    } else {
        [self.paymentFlowDriverDelegate onPaymentComplete:result error:nil];
    }
}

- (nonnull NSString *)paymentFlowName {
    return @"paypal-commerce-platform-contingency";
}

@end

#import "PYPLCardContingencyRequest.h"
#import "PYPLCardContingencyResult.h"
#import "PYPLClient.h"

@interface PYPLCardContingencyRequest ()

@property (strong, nonatomic) NSURL *contingencyURL;
@property (nonatomic, weak) id<BTPaymentFlowDriverDelegate> paymentFlowDriverDelegate;

@end

@implementation PYPLCardContingencyRequest

- (instancetype)initWithContingencyURL:(NSURL *)contingencyURL {
    self = [super init];
    if (self) {
        _contingencyURL = contingencyURL;
    }

    return self;
}

- (void)handleRequest:(BTPaymentFlowRequest *)request client:(__unused BTAPIClient *)apiClient paymentDriverDelegate:(id<BTPaymentFlowDriverDelegate>)delegate {
    self.paymentFlowDriverDelegate = delegate;
    PYPLCardContingencyRequest *contingencyRequest = (PYPLCardContingencyRequest *)request;

    NSString *redirectURLString = [NSString stringWithFormat:@"%@://x-callback-url/paypal-sdk/card-contingency", [BTAppSwitch sharedInstance].returnURLScheme];
    NSURLQueryItem *redirectQueryItem = [NSURLQueryItem queryItemWithName:@"redirect_uri" value:redirectURLString];

    NSURLComponents *contingencyURLComponents = [NSURLComponents componentsWithURL:contingencyRequest.contingencyURL resolvingAgainstBaseURL:NO];
    NSMutableArray<NSURLQueryItem *> *queryItems = [contingencyURLComponents.queryItems mutableCopy] ?: [NSMutableArray new];
    contingencyURLComponents.queryItems = [queryItems arrayByAddingObject:redirectQueryItem];

    [delegate onPaymentWithURL:contingencyURLComponents.URL error:nil];
}

- (BOOL)canHandleAppSwitchReturnURL:(NSURL *)url sourceApplication:(__unused NSString *)sourceApplication {
    return [url.host isEqualToString:@"x-callback-url"] && [url.path hasPrefix:@"/paypal-sdk/card-contingency"];
}

- (void)handleOpenURL:(nonnull NSURL *)url {
    PYPLCardContingencyResult *result = [[PYPLCardContingencyResult alloc] initWithURL:url];

    if (result.error.length) {
        NSError *validateError = [[NSError alloc] initWithDomain:PYPLClientErrorDomain
                                                            code:0
                                                        userInfo:@{NSLocalizedDescriptionKey: result.errorDescription ?: @"contingency error"}];

        [self.paymentFlowDriverDelegate onPaymentComplete:nil error:validateError];
    } else {
        [self.paymentFlowDriverDelegate onPaymentComplete:result error:nil];
    }
}

- (nonnull NSString *)paymentFlowName {
    return @"paypal-sdk-contingency";
}

@end

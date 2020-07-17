#import "BTAPIClient+Analytics_Internal.h"
#import "PYPLAPIClient.h"
#import "PYPLClient.h"

NSString * const PYPLAPIClientErrorDomain = @"com.braintreepayments.PYPLAPIClientErrorDomain";

@interface PYPLAPIClient()

@property (nonatomic, strong) BTPayPalIDToken *payPalIDToken;

@end

@implementation PYPLAPIClient

- (nullable instancetype)initWithIDToken:(NSString *)idToken {
    if (self = [super init]) {
        _urlSession = NSURLSession.sharedSession;
        _braintreeAPIClient = [[BTAPIClient alloc] initWithAuthorization:idToken];
        
        NSError *error;
        _payPalIDToken = [[BTPayPalIDToken alloc] initWithIDTokenString:idToken error:&error];
        if (error || !_payPalIDToken) {
            NSLog(@"[PayPalSDK] %@", error.localizedDescription ?: @"Error initializing PayPal ID Token");
            return nil;
        }
    }
    
    return self;
}

- (void)validatePaymentMethod:(BTPaymentMethodNonce *)paymentMethod
                   forOrderId:(NSString *)orderId
                      with3DS:(BOOL)isThreeDSecureRequired
                   completion:(void (^)(PYPLValidationResult * _Nullable result, NSError * _Nullable error))completion {
    
    NSString *urlString = [NSString stringWithFormat:@"%@/v2/checkout/orders/%@/validate-payment-method", self.payPalIDToken.basePayPalURL, orderId];
    NSError *createRequestError;
    
    NSURLRequest *urlRequest = [self createValidateURLRequest:[NSURL URLWithString:urlString]
                                       withPaymentMethodNonce:paymentMethod.nonce
                                                      with3DS:isThreeDSecureRequired
                                                        error:&createRequestError];
    if (!urlRequest) {
        completion(nil, createRequestError);
        return;
    }

    NSDictionary *fptiData = @{
        @"state_name": @"paypal_sdk",
        @"context_type": @"cart-ID",
        @"context_id": orderId,
        // TODO - additional data
        @"paypal_sdk_v": @"SDK_VERSION",
        @"rcvr_id": @"TODO_PP_MERCHANT_ID"
    };
    
    [[self.urlSession dataTaskWithRequest:urlRequest completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                [self sdkAnalyticsEvent:@"ios.paypal-sdk.validate.failed" with:fptiData];
                completion(nil, error);
                return;
            }
            
            BTJSON *json = [[BTJSON alloc] initWithData:data];
            NSLog(@"Validate result: %@", json); // TODO - remove this logging before pilot
            PYPLValidationResult *result = [[PYPLValidationResult alloc] initWithJSON:json];
            
            NSInteger statusCode = ((NSHTTPURLResponse *) response).statusCode;
            if (statusCode >= 400) {
                // Contingency error represents 3DS challenge required
                if ([result.issueType isEqualToString:@"CONTINGENCY"]) {
                    completion(result, nil);
                    return;
                } else {
                    NSString *errorDescription;
                    if (result.issueType) {
                        errorDescription = result.issueType;
                    } else if (result.message) {
                        errorDescription = result.message;
                    } else {
                        errorDescription = @"Validation Error";
                    }
                    
                    NSError *validateError = [[NSError alloc] initWithDomain:PYPLAPIClientErrorDomain
                                                                        code:0 userInfo:@{NSLocalizedDescriptionKey: errorDescription}];
                    
                    [self sdkAnalyticsEvent:@"ios.paypal-sdk.validate.failed" with:fptiData];
                    completion(nil, validateError);
                    return;
                }
            }
            
            [self sdkAnalyticsEvent:@"ios.paypal-sdk.validate.succeeded" with:fptiData];
            completion(result, nil);
        });
    }] resume];
}

- (nullable NSURLRequest *)createValidateURLRequest:(NSURL *)url
                             withPaymentMethodNonce:(NSString *)paymentMethodNonce
                                            with3DS:(BOOL)isThreeDSecureRequired
                                              error:(NSError **)error {
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    request.HTTPMethod = @"POST";
    [request setValue:[NSString stringWithFormat:@"Bearer %@", self.payPalIDToken.token] forHTTPHeaderField:@"Authorization"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    NSDictionary *body = [self constructValidatePayload:paymentMethodNonce with3DS:isThreeDSecureRequired];
    
    NSData *bodyData = [NSJSONSerialization dataWithJSONObject:body options:0 error:error];
    if (!bodyData) {
        return nil;
    }
    request.HTTPBody = bodyData;
    
    return [request copy];
}

- (NSDictionary *)constructValidatePayload:(NSString *)nonce
                                   with3DS:(BOOL) isThreeDSecureRequired {
    NSMutableDictionary *tokenParameters = [NSMutableDictionary new];
    NSMutableDictionary *validateParameters = [NSMutableDictionary new];
    
    tokenParameters[@"id"] = nonce;
    tokenParameters[@"type"] = @"NONCE";
    
    validateParameters[@"payment_source"] = @{
        @"token" : tokenParameters,
        @"contingencies": (isThreeDSecureRequired ? @[@"3D_SECURE"] : @[])
    };
    
    NSLog(@"🍏Validate Request Params: %@", validateParameters);  // TODO - remove this logging before pilot
    return (NSDictionary *)validateParameters;
}

- (void)sdkAnalyticsEvent:(NSString *)eventKind with:(NSDictionary *)additionalData {
    [self.braintreeAPIClient sendSDKEvent:eventKind with:additionalData];
}

@end
#

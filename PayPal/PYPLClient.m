#import "BTAPIClient+Analytics_Internal.h"
#import "PYPLClient_Internal.h"
#import "PYPLCardContingencyRequest.h"
#import "PYPLPayPalPaymentFlowRequest.h"

NSString * const PYPLClientErrorDomain = @"com.paypal.PYPLClientErrorDomain";

@interface PYPLClient() <PKPaymentAuthorizationViewControllerDelegate>

@property (nonatomic, copy) NSString *orderId;
@property (nonatomic, copy) void (^applePayCompletionBlock)(PYPLApplePayCheckoutResult * _Nullable result, NSError * _Nullable, PYPLApplePayResultHandler successHandler);

@end

@implementation PYPLClient

#pragma mark - Properties

// For testing
static Class PayPalDataCollectorClass;
static NSString *PayPalDataCollectorClassString = @"PPDataCollector";

#pragma mark - Initialization

- (void)setOrderId:(NSString *)orderId {
    _orderId = orderId;
    [PayPalDataCollectorClass clientMetadataID:_orderId];
}

- (nullable instancetype)initWithIDToken:(NSString *)idToken {
    self = [super init];
    if (self) {
        NSError *error;
        _payPalIDToken = [[BTPayPalIDToken alloc] initWithIDTokenString:idToken error:&error];
        if (error || !_payPalIDToken) {
            NSLog(@"[PayPalSDK]: Error initializing PayPal ID Token. Error code: %ld", (long) error.code);
            return nil;
        }

        _braintreeAPIClient = [[BTAPIClient alloc] initWithAuthorization:idToken];
        if (!_braintreeAPIClient) {
            return nil;
        }

        _applePayClient = [[BTApplePayClient alloc] initWithAPIClient:_braintreeAPIClient];
        _cardClient = [[BTCardClient alloc] initWithAPIClient:_braintreeAPIClient];
        _paymentFlowDriver = [[BTPaymentFlowDriver alloc] initWithAPIClient:_braintreeAPIClient];
        _payPalAPIClient = [[PYPLAPIClient alloc] initWithIDToken:idToken];
    }

    return self;
}

#pragma mark - Checkout with Card

- (void)checkoutWithCard:(NSString *)orderID
                    card:(BTCard *)card
              completion:(void (^)(PYPLCardCheckoutResult * _Nullable result, NSError * _Nullable error))completion {
    self.orderId = orderID;
    [self.payPalAPIClient sdkAnalyticsEvent:@"ios.paypal-sdk.card-checkout.started" with:[self fptiDefaults]];

    [self.cardClient tokenizeCard:card completion:^(BTCardNonce * tokenizedCard, NSError __unused *btError) {
        if (tokenizedCard) {
            [self validateTokenizedCard:tokenizedCard completion:^(BOOL success, NSError *error) {
                if (success) {
                    PYPLCardCheckoutResult *checkoutResult = [[PYPLCardCheckoutResult alloc] initWithOrderID:self.orderId];

                    [self.payPalAPIClient sdkAnalyticsEvent:@"ios.paypal-sdk.card-checkout.succeeded" with:[self fptiDefaults]];
                    completion(checkoutResult, nil);
                } else {
                    [self.payPalAPIClient sdkAnalyticsEvent:@"ios.paypal-sdk.card-checkout.failed" with:[self fptiDefaults]];
                    completion(nil, error);
                }
            }];
        } else {
            [self.payPalAPIClient sdkAnalyticsEvent:@"ios.paypal-sdk.card-checkout.failed" with:[self fptiDefaults]];
            NSError *error = [NSError errorWithDomain:PYPLClientErrorDomain
                                                 code:PYPLClientErrorTokenizationFailure
                                             userInfo:@{NSLocalizedDescriptionKey: @"An internal error occured during checkout. Please contact Support."}];
            completion(nil, error);
        }
    }];
}

- (void)validateTokenizedCard:(BTCardNonce *)tokenizedCard
                   completion:(void (^)(BOOL success, NSError * _Nullable error))completion {
    [self.payPalAPIClient validatePaymentMethod:tokenizedCard
                                     forOrderId:self.orderId
                                        with3DS:YES
                                     completion:^(PYPLValidationResult *result, NSError __unused *error) {
                                            if (error) {
                                                completion(NO, error);
                                            } else if (result.contingencyURL) {
                                                PYPLCardContingencyRequest *contingencyRequest = [[PYPLCardContingencyRequest alloc] initWithContingencyURL:result.contingencyURL];
                                                [self.payPalAPIClient sdkAnalyticsEvent:@"ios.paypal-sdk.card-contingency.started" with:[self fptiDefaults]];

                                                self.paymentFlowDriver.viewControllerPresentingDelegate = self.presentingDelegate;
                                                [self.paymentFlowDriver startPaymentFlow:contingencyRequest completion:^(BTPaymentFlowResult *result, NSError *error) {
                                                    if (result) {
                                                        [self.payPalAPIClient sdkAnalyticsEvent:@"ios.paypal-sdk.card-contingency.succeeded" with:[self fptiDefaults]];
                                                        completion(YES, nil);
                                                    } else {
                                                        [self.payPalAPIClient sdkAnalyticsEvent:@"ios.paypal-sdk.card-contingency.failed" with:[self fptiDefaults]];
                                                        completion(NO, [self convertToPYPLPaymentFlowError:error]);
                                                    }
                                                }];
                                            } else {
                                                [self.payPalAPIClient sdkAnalyticsEvent:@"ios.paypal-sdk.card-contingency.no-challenge" with:[self fptiDefaults]];
                                                completion(YES, nil);
                                            }
    }];
}

#pragma mark - Checkout with PayPal

- (void)checkoutWithPayPal:(NSString *)orderId
                completion:(void (^)(PYPLPayPalCheckoutResult * _Nullable result, NSError * _Nullable error))completion {
    self.orderId = orderId;
    [self.payPalAPIClient sdkAnalyticsEvent:@"ios.paypal-sdk.paypal-checkout.started" with:[self fptiDefaults]];

    NSString *baseURL;
    if (self.payPalIDToken.environment == BTPayPalIDTokenEnvironmentProd) {
        baseURL = @"https://www.paypal.com";
    } else if (self.payPalIDToken.environment == BTPayPalIDTokenEnvironmentSand) {
        baseURL = @"https://www.sandbox.paypal.com";
    } else if (self.payPalIDToken.environment == BTPayPalIDTokenEnvironmentStage) {
        baseURL = @"https://www.msmaster.qa.paypal.com";
    }

    NSURL *payPalCheckoutURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@/checkoutnow?token=%@", baseURL, self.orderId]];

    PYPLPayPalPaymentFlowRequest *request = [[PYPLPayPalPaymentFlowRequest new] initWithCheckoutURL:payPalCheckoutURL];

    self.paymentFlowDriver.viewControllerPresentingDelegate = self.presentingDelegate;
    [self.paymentFlowDriver startPaymentFlow:request completion:^(BTPaymentFlowResult * __unused result, NSError *error) {
        if (error) {
            [self.payPalAPIClient sdkAnalyticsEvent:@"ios.paypal-sdk.paypal-checkout.failed" with:[self fptiDefaults]];
            completion(nil, [self convertToPYPLPaymentFlowError:error]);
            return;
        }
        PYPLPayPalCheckoutResult *checkoutResult = [[PYPLCheckoutResult alloc] initWithOrderID:self.orderId];

        [self.payPalAPIClient sdkAnalyticsEvent:@"ios.paypal-sdk.paypal-checkout.succeeded" with:[self fptiDefaults]];
        completion(checkoutResult, nil);
    }];
}

#pragma mark - Checkout with ApplePay

- (void)checkoutWithApplePay:(NSString * __unused)orderId
              paymentRequest:(PKPaymentRequest *)paymentRequest
                  completion:(void (^)(PYPLApplePayCheckoutResult * _Nullable result, NSError * _Nullable error, PYPLApplePayResultHandler resultHandler))completion {
    self.orderId = orderId;
    self.applePayCompletionBlock = completion;
    [self.payPalAPIClient sdkAnalyticsEvent:@"ios.paypal-sdk.apple-pay-checkout.started" with:[self fptiDefaults]];

    [self.applePayClient paymentRequest:^(PKPaymentRequest *defaultPaymentRequest, NSError *error) {
        if (defaultPaymentRequest) {
            paymentRequest.countryCode = paymentRequest.countryCode ?: defaultPaymentRequest.countryCode;
            paymentRequest.currencyCode = paymentRequest.currencyCode ?: defaultPaymentRequest.currencyCode;
            paymentRequest.merchantIdentifier = paymentRequest.merchantIdentifier ?: defaultPaymentRequest.merchantIdentifier;

            // TODO: - revert after PP supports additional networks
            // For MVP, PP processor interaction is only coded for Visa and Mastercard
            // When fetching default support networks from BT config - only include Visa & MC
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@ || SELF MATCHES %@", @"Visa", @"MasterCard"];
            NSArray *defaultSupportedNetworks = [defaultPaymentRequest.supportedNetworks filteredArrayUsingPredicate:predicate];

            paymentRequest.supportedNetworks = paymentRequest.supportedNetworks ?: defaultSupportedNetworks;

            PKPaymentAuthorizationViewController *authorizationViewController = [[PKPaymentAuthorizationViewController alloc] initWithPaymentRequest:paymentRequest];

            if (!authorizationViewController) {
                [self.payPalAPIClient sdkAnalyticsEvent:@"ios.paypal-sdk.apple-pay-sheet.failed" with:[self fptiDefaults]];
                NSError *error = [[NSError alloc] initWithDomain:PYPLClientErrorDomain
                                                            code:0
                                                        userInfo:@{NSLocalizedDescriptionKey: @"Apple Pay authorizationViewController failed to initialize"}];
                self.applePayCompletionBlock(nil, error, nil);
                return;
            }

            authorizationViewController.delegate = self;
            [self.presentingDelegate paymentDriver:self requestsPresentationOfViewController:authorizationViewController];
        } else {
            [self.payPalAPIClient sdkAnalyticsEvent:@"ios.paypal-sdk.apple-pay-payment-request.failed" with:[self fptiDefaults]];
            self.applePayCompletionBlock(nil, error, nil);
        }
    }];
}

- (void)tokenizeAndValidateApplePayPayment:(PKPayment *)payment completion:(void (^)(PYPLCheckoutResult * _Nullable result, NSError * _Nullable error))completion {
    [self.applePayClient tokenizeApplePayPayment:payment completion:^(BTApplePayCardNonce *tokenizedApplePayPayment, NSError *btError) {
        if (!tokenizedApplePayPayment || btError) {
            [self.payPalAPIClient sdkAnalyticsEvent:@"ios.paypal-sdk.apple-pay-checkout.failed" with:[self fptiDefaults]];
            NSError *error = [NSError errorWithDomain:PYPLClientErrorDomain
                                                 code:PYPLClientErrorTokenizationFailure
                                             userInfo:@{NSLocalizedDescriptionKey: @"An internal error occured during checkout. Please contact Support."}];
            completion(nil, error);
            return;
        }

        [self.payPalAPIClient validatePaymentMethod:tokenizedApplePayPayment
                                         forOrderId:self.orderId
                                            with3DS:NO
                                         completion:^(PYPLValidationResult * __unused result, NSError *error) {
            if (!result || error) {
                [self.payPalAPIClient sdkAnalyticsEvent:@"ios.paypal-sdk.apple-pay-checkout.failed" with:[self fptiDefaults]];
                completion(nil, error);
                return;
            }

            PYPLApplePayCheckoutResult *checkoutResult = [[PYPLApplePayCheckoutResult alloc] initWithOrderID:self.orderId payment:payment];

            [self.payPalAPIClient sdkAnalyticsEvent:@"ios.paypal-sdk.apple-pay-checkout.succeeded" with:[self fptiDefaults]];
            completion(checkoutResult, error);
        }];
    }];
}

#pragma mark - PKPaymentAuthorizationViewControllerDelegate

- (void)paymentAuthorizationViewControllerDidFinish:(nonnull PKPaymentAuthorizationViewController *)controller {
    [self.presentingDelegate paymentDriver:self requestsDismissalOfViewController:controller];
}

// iOS 11+ delegate method
- (void)paymentAuthorizationViewController:(PKPaymentAuthorizationViewController * __unused)controller
                       didAuthorizePayment:(PKPayment *)payment
                                   handler:(void (^)(PKPaymentAuthorizationResult * _Nonnull))completion API_AVAILABLE(ios(11.0)) {
    [self tokenizeAndValidateApplePayPayment:payment completion:^(PYPLCheckoutResult *result, NSError *error) {
        self.applePayCompletionBlock(result, error, ^(BOOL success) {
            if (success) {
                [self.payPalAPIClient sdkAnalyticsEvent:@"ios.paypal-sdk.apple-pay-result-handler.true" with:[self fptiDefaults]];
                completion([[PKPaymentAuthorizationResult alloc] initWithStatus:PKPaymentAuthorizationStatusSuccess errors:nil]);
            } else {
                [self.payPalAPIClient sdkAnalyticsEvent:@"ios.paypal-sdk.apple-pay-result-handler.false" with:[self fptiDefaults]];
                completion([[PKPaymentAuthorizationResult alloc] initWithStatus:PKPaymentAuthorizationStatusFailure errors:nil]);
            }
        });
    }];
}

// pre-iOS 11 delegate method
- (void)paymentAuthorizationViewController:(__unused PKPaymentAuthorizationViewController *)controller
                       didAuthorizePayment:(PKPayment *)payment
                                completion:(void (^)(PKPaymentAuthorizationStatus status))completion {
    [self tokenizeAndValidateApplePayPayment:payment completion:^(PYPLCheckoutResult *result, NSError *error) {
        self.applePayCompletionBlock(result, error, ^(BOOL success) {
            if (success) {
                [self.payPalAPIClient sdkAnalyticsEvent:@"ios.paypal-sdk.apple-pay-result-handler.true" with:[self fptiDefaults]];
                completion(PKPaymentAuthorizationStatusSuccess);
            } else {
                [self.payPalAPIClient sdkAnalyticsEvent:@"ios.paypal-sdk.apple-pay-result-handler.false" with:[self fptiDefaults]];
                completion(PKPaymentAuthorizationStatusFailure);
            }
        });
    }];
}

#pragma mark - Helpers

/** Convert BT errors from PaymentFlowDriver failure to be PP merchant friendly. */
- (NSError *)convertToPYPLPaymentFlowError:(NSError *)error {
    if ([error.domain hasPrefix:@"PYPL"]) {
        return error;
    } else {
        NSError *PYPLError = [[NSError alloc] initWithDomain:PYPLClientErrorDomain
                                                    code:PYPLClientErrorPaymentFlowDriverFailure
                                                userInfo:@{NSLocalizedDescriptionKey:error.localizedDescription ?: @"An error occured during checkout."}];
        return PYPLError;
    }
}

/** FPTI default values for PYPLClient */
- (NSMutableDictionary *)fptiDefaults {
    NSMutableDictionary *defaults = [NSMutableDictionary dictionaryWithDictionary:@{
        @"state_name": @"paypal_sdk",
        // TODO - additional data
        @"paypal_sdk_v": @"SDK_VERSION",
        @"rcvr_id": @"TODO_PP_MERCHANT_ID"
    }];
    if (_orderId) {
        [defaults setObject:_orderId forKey:@"context_id"];
        [defaults setObject:@"cart-ID" forKey:@"context_type"];
    }
    return defaults;
}

#pragma mark - Test Helpers

+ (void)setPayPalDataCollectorClass:(Class)payPalDataCollectorClass {
    PayPalDataCollectorClass = payPalDataCollectorClass;
}

@end

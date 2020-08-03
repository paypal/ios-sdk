#import "PYPLClient.h"
#import "PYPLAPIClient.h"

NS_ASSUME_NONNULL_BEGIN

@interface PYPLClient ()

@property (nonatomic, strong) BTApplePayClient *applePayClient;
@property (nonatomic, strong) PYPLAPIClient *payPalAPIClient;
@property (nonatomic, strong) BTCardClient *cardClient;
@property (nonatomic, strong) BTPaymentFlowDriver *paymentFlowDriver;
@property (nonatomic, strong) BTAPIClient *braintreeAPIClient;
@property (nonatomic, strong) BTPayPalIDToken *payPalIDToken;

/**
 The `PPDataCollector` class, exposed internally for injecting test doubles for unit tests
 */
+ (void)setPayPalDataCollectorClass:(nonnull Class)payPalDataCollectorClass;

/**
 Error codes associated with `PYPLClient`.
 */
typedef NS_ENUM(NSInteger, PYPLClientError) {
    /// Unknown error
    PYPLClientErrorUnknown = 0,

    /// Tokenization via Braintree failed
    PYPLClientErrorTokenizationFailure,

    /// BTPaymentFlowDriver.startPaymentFlow returned error
    PYPLClientErrorPaymentFlowDriverFailure,
};

@end

NS_ASSUME_NONNULL_END

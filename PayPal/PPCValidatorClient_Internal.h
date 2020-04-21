#import "PPCValidatorClient.h"
#import "PPCAPIClient.h"

NS_ASSUME_NONNULL_BEGIN

@interface PPCValidatorClient ()

@property (nonatomic, strong) BTApplePayClient *applePayClient;
@property (nonatomic, strong) PPCAPIClient *payPalAPIClient;
@property (nonatomic, strong) BTCardClient *cardClient;
@property (nonatomic, strong) BTPaymentFlowDriver *paymentFlowDriver;
@property (nonatomic, strong) BTAPIClient *braintreeAPIClient;
@property (nonatomic, strong) BTPayPalUAT *payPalUAT;

/**
 The `PPDataCollector` class, exposed internally for injecting test doubles for unit tests
 */
+ (void)setPayPalDataCollectorClass:(nonnull Class)payPalDataCollectorClass;

/**
 Error codes associated with `PPCValidatorClient`.
 */
typedef NS_ENUM(NSInteger, PPCValidatorError) {
    /// Unknown error
    PPCValidatorErrorUnknown = 0,

    /// Tokenization via Braintree failed
    PPCValidatorErrorTokenizationFailure,

    /// BTPaymentFlowDriver.startPaymentFlow returned error
    PPCValidatorErrorPaymentFlowDriverFailure,
};

@end

NS_ASSUME_NONNULL_END

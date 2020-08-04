#if __has_include("BraintreeCore.h")
#import "BraintreeCore.h"
#else
#import <BraintreeCore/BraintreeCore.h>
#endif

#if __has_include("BraintreeCard.h")
#import "BraintreeCard.h"
#else
#import <BraintreeCard/BraintreeCard.h>
#endif

#import "PYPLValidationResult.h"

NS_ASSUME_NONNULL_BEGIN

@interface PYPLAPIClient : NSObject

@property (nonatomic, strong) NSURLSession *urlSession;
@property (nonatomic, strong) BTAPIClient *braintreeAPIClient;

- (nullable instancetype)initWithIDToken:(NSString *)idToken;

- (void)validatePaymentMethod:(BTPaymentMethodNonce *)paymentMethod
                   forOrderId:(NSString *)orderId
                      with3DS:(BOOL)isThreeDSecureRequired
                   completion:(void (^)(PYPLValidationResult * _Nullable result, NSError * _Nullable error))completion;

- (NSDictionary *)constructValidatePayload:(NSString *)nonce
                                   with3DS:(BOOL)isThreeDSecureRequired;

- (nullable NSURLRequest *)createValidateURLRequest:(NSURL *)url
                             withPaymentMethodNonce:(NSString *)paymentMethodNonce
                                            with3DS:(BOOL)isThreeDSecureRequired
                                              error:(NSError **)error;

- (void)sdkAnalyticsEvent:(NSString *)eventName with:(NSDictionary *)additionalData;

@end

NS_ASSUME_NONNULL_END

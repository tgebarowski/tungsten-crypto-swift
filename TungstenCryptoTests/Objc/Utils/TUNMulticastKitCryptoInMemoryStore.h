//
//  Copyright © 2016 Tungsten Labs UG. All rights reserved.
//
//  Licensed according to https://www.gnu.org/licenses/gpl-3.0.html
//

#import <Foundation/Foundation.h>
#import <TungstenCrypto/TungstenCrypto-Swift.h>

@interface TUNMulticastKitCryptoInMemoryStore : NSObject <MulticastCryptoStore>

@property NSMutableDictionary *sessionRecords;

- (instancetype)initWithUserId:(NSString *)userId localRegistrationId:(NSString*)localRegistrationId deviceId:(NSString*)deviceId;
- (NSArray *)topUpInitKeysTo:(NSUInteger)desiredNumberOfInitKeys excludedIds:(NSArray<NSNumber *> *)excludedIds createdNewInitKeys:(BOOL *)createdNewInitKeys;

+ (NSArray<InitKeyRecord *> * _Nonnull)initKeysWithStartingId:(NSInteger)withStartingId count:(NSInteger)count SWIFT_METHOD_FAMILY(none) SWIFT_WARN_UNUSED_RESULT;
- (BOOL)hasLocalIdentity SWIFT_WARN_UNUSED_RESULT;
- (BOOL)hasAnySessions SWIFT_WARN_UNUSED_RESULT;
- (void)createLocalIdentityWith:(NSInteger)deviceId localIdentityId:(NSInteger)localIdentityId;
- (void)deleteLocalIdentity;
- (SignedInitKeyRecord * _Nullable)localSignedInitKey SWIFT_WARN_UNUSED_RESULT;
- (NSString * _Nullable)localSignedInitKeyId SWIFT_WARN_UNUSED_RESULT;
- (NSArray<InitKeyRecord *> * _Nonnull)loadInitKeys SWIFT_WARN_UNUSED_RESULT;
- (NSArray<InitKeyRecord *> * _Nonnull)topUpInitKeysWithExcludedIds:(NSArray<NSNumber *> * _Nonnull)excludedIds createdNewInitKeys:(BOOL * _Nonnull)createdNewInitKeys SWIFT_WARN_UNUSED_RESULT;

@end

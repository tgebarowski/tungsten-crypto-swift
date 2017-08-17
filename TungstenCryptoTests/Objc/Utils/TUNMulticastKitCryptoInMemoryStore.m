//
//  Copyright © 2016 Tungsten Labs UG. All rights reserved.
//
//  Licensed according to https://www.gnu.org/licenses/gpl-3.0.html
//

#import "TUNMulticastKitCryptoInMemoryStore.h"
#import "CryptoDebug.h"
#import "NSData+crypto_AES.h"

@interface TUNMulticastKitCryptoInMemoryStore ()

@property NSMutableDictionary *initialKeyStore;
@property NSMutableDictionary *signedInitKeyStore;

@property NSMutableDictionary *trustedKeys;

@property KeyPair *_identityKeyPair;
@property NSString* _localRegistrationId;

@property (nonatomic, copy, readwrite) NSString *userId;
@property (nonatomic, readwrite) NSString* deviceId;

@property (nonatomic, strong) SignedInitKeyRecord *localSignedInitKey;
@property (nonatomic, strong) NSString* localSignedInitKeyId;

@end

@implementation TUNMulticastKitCryptoInMemoryStore

# pragma mark General

- (instancetype)initWithUserId:(NSString *)userId localRegistrationId:(NSString*)localRegistrationId deviceId:(NSString*)deviceId {
    self = [super init];
    
    if (self) {
        
        __identityKeyPair     = [[CryptoToolkit.sharedInstance.configuration keyAgreement] generateKeyPair];
        __localRegistrationId = localRegistrationId;
        
        _initialKeyStore = [NSMutableDictionary dictionary];
        _signedInitKeyStore = [NSMutableDictionary dictionary];
        _trustedKeys = [NSMutableDictionary dictionary];
        _sessionRecords = [NSMutableDictionary dictionary];
        _userId = userId;
        _deviceId = deviceId;
        _localSignedInitKeyId = @(arc4random_uniform(pow(2, 31) - 1)).stringValue;
    }
    
    return self;
}

# pragma mark Signed InitKey Store

- (NSString*)localSignedInitKeyId {
    return _localSignedInitKeyId;
}

- (SignedInitKeyRecord *)localSignedInitKey
{
    if (!_localSignedInitKey) {
        KeyPair *signedKeyPair = [[CryptoToolkit.sharedInstance.configuration keyAgreement] generateKeyPair];
        NSData    *signature = [[CryptoToolkit.sharedInstance.configuration keyAgreement] signWithData:signedKeyPair.publicKey keyPair:self.identityKeyPair];
        
        SignedInitKeyRecord *signedInitKey = [[SignedInitKeyRecord alloc] initWithId:_localSignedInitKeyId
                                                                          keyPair:signedKeyPair
                                                                        signature:signature
                                                                      generatedAt:[NSDate date]];
        
        [self storeSignedInitKey:self.localSignedInitKeyId signedInitKeyRecord:signedInitKey];
        _localSignedInitKey = signedInitKey;
    }
    
    return _localSignedInitKey;
}

- (SignedInitKeyRecord *)loadSignedInitKey:(NSString*)signedInitKeyId{
    if (![[self.signedInitKeyStore allKeys] containsObject:signedInitKeyId]) {
        @throw [NSException exceptionWithName:@"InvalidKeyIdException" reason:@"No such signedinitKeyrecord" userInfo:nil];
    }
    
    return [self.signedInitKeyStore objectForKey:signedInitKeyId];
}

- (NSArray *)loadSignedInitKeys{
    NSMutableArray *results = [NSMutableArray array];
    
    for (SignedInitKeyRecord *signedInitKey in [self.signedInitKeyStore allValues]) {
        [results addObject:signedInitKey];
    }
    
    return results;
}

- (void)storeSignedInitKey:(NSString*)signedInitKeyId signedInitKeyRecord:(SignedInitKeyRecord *)signedInitKeyRecord{
    [self.signedInitKeyStore setObject:signedInitKeyRecord forKey:signedInitKeyId];
}

- (BOOL)containsSignedInitKey:(NSString*)signedInitKeyId{
    if ([[self.signedInitKeyStore allKeys] containsObject:signedInitKeyId]) {
        return TRUE;
    }
    
    return FALSE;
}

- (void)removeSignedInitKey:(NSString*)signedInitKeyId{
    [self.signedInitKeyStore removeObjectForKey:signedInitKeyId];
}

# pragma mark InitKey Store

- (InitKeyRecord *)loadInitKey:(int)initKeyId{    
    return [self.initialKeyStore objectForKey:[NSNumber numberWithInt:initKeyId]];
}

- (NSArray *)loadInitKeys{
    NSMutableArray *results = [NSMutableArray array];
    
    for (InitKeyRecord *initKey in [self.initialKeyStore allValues]) {
        [results addObject:initKey];
    }
    
    return results;
}

- (void)storeInitKey:(int)initKeyId initKeyRecord:(InitKeyRecord *)record {
    [self.initialKeyStore setObject:record forKey:[NSNumber numberWithInt:initKeyId]];
}

- (BOOL)containsInitKey:(int)initKeyId{
    if ([[self.initialKeyStore allKeys] containsObject:[NSNumber numberWithInteger:initKeyId]]) {
        return TRUE;
    }
    
    return FALSE;
}

- (void)removeInitKey:(int)initKeyId{
    [self.initialKeyStore removeObjectForKey:[NSNumber numberWithInt:initKeyId]];
}

# pragma mark IdentityKeyStore

- (KeyPair *)identityKeyPair{
    return __identityKeyPair;
}

- (NSString*)localRegistrationId{
    return __localRegistrationId;
}

- (void)saveRemoteIdentity:(NSData *)identityKey recipientId:(NSString*)recipientId deviceId:(int)deviceId
{
    if (!self.trustedKeys[recipientId]) {
        self.trustedKeys[recipientId] = @{}.mutableCopy;
    }
    
    self.trustedKeys[recipientId][@(deviceId)] = identityKey;
}

- (BOOL)isTrustedIdentityKey:(NSData *)identityKey recipientId:(NSString*)recipientId deviceId:(int)deviceId
{
    if (!self.trustedKeys[recipientId]) {
        self.trustedKeys[recipientId] = @{}.mutableCopy;
    }
    
    NSData *data = self.trustedKeys[recipientId][@(deviceId)];
    
    if (data) {
        return [data isEqualToData:identityKey];
    }
    
    return YES; // Trust on first use
}

# pragma mark Session Store

-(SessionRecord*)loadSession:(NSString*)contactIdentifier deviceId:(int)deviceId{
    id archivedSessionRecord = [[self deviceSessionRecordsForContactIdentifier:contactIdentifier] objectForKey:[NSNumber numberWithInteger:deviceId]];
    
    SessionRecord *sessionRecord = [NSKeyedUnarchiver unarchiveObjectWithData:archivedSessionRecord];
    if (!sessionRecord) {
        sessionRecord = [SessionRecord new];
    }
    
    return sessionRecord;
}

- (NSArray*)subDevicesSessions:(NSString*)contactIdentifier{
    return [[self deviceSessionRecordsForContactIdentifier:contactIdentifier] allKeys];
}

- (NSDictionary*)deviceSessionRecordsForContactIdentifier:(NSString*)contactIdentifier{
    return [self.sessionRecords objectForKey:contactIdentifier];
}

- (void)storeSession:(NSString*)contactIdentifier deviceId:(int)deviceId session:(SessionRecord *)session {
    NSAssert(session, @"Session can't be nil");

    NSData *archivedSession = [NSKeyedArchiver archivedDataWithRootObject:session];
    [self.sessionRecords setObject:@{[NSNumber numberWithInt:deviceId]: archivedSession} forKey:contactIdentifier];
}

- (BOOL)containsSession:(NSString*)contactIdentifier deviceId:(int)deviceId{
    
    if ([[self.sessionRecords objectForKey:contactIdentifier] objectForKey:[NSNumber numberWithInt:deviceId]]){
        return YES;
    }
    return NO;
}

-(NSArray<InitKeyRecord *> *)topUpInitKeysTo:(NSUInteger)desiredNumberOfInitKeys excludedIds:(NSArray<NSNumber *> *)excludedIds createdNewInitKeys:(BOOL *)createdNewInitKeys
{
    NSMutableArray *currentInitKeysRecords = [self loadInitKeys].mutableCopy;
    NSUInteger currentInitKeysCount = currentInitKeysRecords.count;
    
    if (currentInitKeysCount < desiredNumberOfInitKeys) {
        __block NSUInteger maxInitKeyId = [self maxInitKeyId:currentInitKeysRecords];
        
        [excludedIds enumerateObjectsUsingBlock:^(NSNumber *excludedId, NSUInteger idx, BOOL *stop) {
            if ([excludedId integerValue] > maxInitKeyId) {
                maxInitKeyId = [excludedId integerValue];
            }
        }];
        
        NSArray *newInitKeysRecords = [[self class] initKeysWithStartingId:maxInitKeyId
                                                                   count:desiredNumberOfInitKeys - currentInitKeysCount];
        
        for (InitKeyRecord *initKeyRecord in newInitKeysRecords) {
            [self storeInitKey:initKeyRecord.id initKeyRecord:initKeyRecord];
            [currentInitKeysRecords addObject:initKeyRecord];
        }
        
        if (createdNewInitKeys) {
            *createdNewInitKeys = YES;
        }
    } else {
        if (createdNewInitKeys) {
            *createdNewInitKeys = NO;
        }
    }
    
    if (currentInitKeysRecords.count > desiredNumberOfInitKeys) {
        [currentInitKeysRecords removeObjectsInRange:NSMakeRange(desiredNumberOfInitKeys - 1, currentInitKeysRecords.count - desiredNumberOfInitKeys)];
    }
    
    return currentInitKeysRecords.copy;
}

- (void)deleteSessionForContact:(NSString*)contactIdentifier deviceId:(NSInteger)deviceId {
    
}

#pragma mark - Helpers

- (NSUInteger)maxInitKeyId:(NSArray *)initKeys
{
    __block NSUInteger maxInitKeyId = 0;
    [initKeys enumerateObjectsUsingBlock:^(InitKeyRecord *initKeyRecord, NSUInteger idx, BOOL *stop) {
        if (initKeyRecord.id > maxInitKeyId) {
            maxInitKeyId = initKeyRecord.id;
        }
    }];
    
    return maxInitKeyId;
}

+ (NSArray *)initKeysWithStartingId:(NSUInteger)startingId count:(NSUInteger)count
{
    NSMutableArray *initKeys = @[].mutableCopy;
    
    for (int i = 0; i < count; i++) {
        [initKeys addObject:[[InitKeyRecord alloc] initWithId:(((startingId + i) % (SHRT_MAX-1)) + 1)
                                                    keyPair:[[CryptoToolkit.sharedInstance.configuration  keyAgreement] generateKeyPair]]];
    }
    
    return initKeys.copy;
}

- (NSString *)debugDescription
{
    NSMutableString *mutableDescription = [@"Multicast Store" mutableCopy];
    [mutableDescription addLine:[NSString stringWithFormat:@"User: %@", self.userId] indentationLevel:0];
    [mutableDescription addLine:@"Sessions" indentationLevel:0];
    NSArray *sortedContactIds = [self.sessionRecords.allKeys sortedArrayUsingSelector:@selector(compare:)];
    for (NSString *key in sortedContactIds) {
        [mutableDescription addLine:[NSString stringWithFormat:@"Contact: %@", key] indentationLevel:1];
        
        NSDictionary *sessionPerDeviceId = self.sessionRecords[key];
        
        NSArray *sortedDeviceIds = [sessionPerDeviceId.allKeys sortedArrayUsingSelector:@selector(compare:)];
        for (NSNumber *deviceId in sortedDeviceIds) {
            [mutableDescription addLine:[NSString stringWithFormat:@"Device: %@", deviceId] indentationLevel:2];
            
            NSData *archivedSessionRecord = sessionPerDeviceId[deviceId];
            SessionRecord *sessionRecord = [NSKeyedUnarchiver unarchiveObjectWithData:archivedSessionRecord];
            if (sessionRecord) {
                [mutableDescription addLine:[NSString stringWithFormat:@"Session Record (fresh: %@)", @(sessionRecord.isFresh)] indentationLevel:3];
                
                [mutableDescription addLine:@"Current Session:" indentationLevel:4];
                [mutableDescription appendString:[sessionRecord.sessionState debugDescriptionWithIndentation:5]];
                [mutableDescription addLine:@"Previous Sessions:" indentationLevel:4];
                for (SessionState *sessionState in sessionRecord.previousStates) {
                    [mutableDescription appendString:[sessionState debugDescriptionWithIndentation:5]];
                }
                if (sessionRecord.previousStates.count == 0) {
                    [mutableDescription addLine:@"<empty>" indentationLevel:5];
                }
            } else {
                [mutableDescription addLine:@"Invalid Session Record" indentationLevel:3];
            }
        }
    }
    if (sortedContactIds.count == 0) {
        [mutableDescription addLine:@"<empty>" indentationLevel:1];
    }
    
    return [mutableDescription copy];
}

@end


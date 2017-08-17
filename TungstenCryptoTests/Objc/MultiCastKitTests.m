//
//  Copyright © 2016 Tungsten Labs UG. All rights reserved.
//
//  Licensed according to https://www.gnu.org/licenses/gpl-3.0.html
//

#import <XCTest/XCTest.h>
#import <TungstenCrypto/TungstenCrypto-Swift.h>
#import "TUNMulticastKitCryptoInMemoryStore.h"
@import TungstenCrypto;

@interface MultiCastKitTests : XCTestCase

@property (nonatomic, strong) TUNMulticastKitCryptoInMemoryStore *aliceStore;
@property (nonatomic, strong) MultiCastKit *aliceMulticastKit;
@property (nonatomic, strong) CryptoInitKeysBundle *aliceInitKeysBundle;
@property (nonatomic, strong) NSMutableArray<NSNumber *> *usedAliceInitKeyIds;

@property (nonatomic, strong) TUNMulticastKitCryptoInMemoryStore *bobStore;
@property (nonatomic, strong) MultiCastKit *bobMulticastKit;
@property (nonatomic, strong) CryptoInitKeysBundle *bobInitKeysBundle;
@property (nonatomic, strong) NSMutableArray<NSNumber *> *usedBobInitKeyIds;

@property (nonatomic, strong) TUNMulticastKitCryptoInMemoryStore *bob2Store;
@property (nonatomic, strong) MultiCastKit *bob2MulticastKit;
@property (nonatomic, strong) CryptoInitKeysBundle *bob2InitKeysBundle;

@end

@implementation MultiCastKitTests

- (void)setUp
{
    [super setUp];
    
    self.usedAliceInitKeyIds = [NSMutableArray array];
    self.usedBobInitKeyIds = [NSMutableArray array];
    
    CryptoConfigurationBuilder* builder = [[CryptoConfigurationBuilder alloc]init];
    [CryptoToolkit.sharedInstance setup:builder.build error:nil];
    
    // Alice store would normally be kept on Alice's device and Bob's store would be kept on Bob's device
    self.aliceStore = [[TUNMulticastKitCryptoInMemoryStore alloc] initWithUserId:@"Alice" localRegistrationId:@"1" deviceId:@"1"];
    self.bobStore = [[TUNMulticastKitCryptoInMemoryStore alloc] initWithUserId:@"Bob" localRegistrationId:@"2" deviceId:@"2"];
    self.bob2Store = [[TUNMulticastKitCryptoInMemoryStore alloc] initWithUserId:@"Bob-2" localRegistrationId:@"3" deviceId:@"3"];
    
    // Create MulticastKit instances
    self.aliceMulticastKit = [[MultiCastKit alloc] initWithCryptoStore:self.aliceStore];
    self.bobMulticastKit = [[MultiCastKit alloc] initWithCryptoStore:self.bobStore];
    self.bob2MulticastKit = [[MultiCastKit alloc] initWithCryptoStore:self.bob2Store];
    
    // Create InitKeysBundles
    NSMutableArray *alicePublicInitKeys = @[].mutableCopy;
    
    
    [[TUNMulticastKitCryptoInMemoryStore initKeysWithStartingId:1 count:20] enumerateObjectsUsingBlock:^(InitKeyRecord *initKeyRecord, NSUInteger idx, BOOL *stop) {
        
        [self.aliceStore storeInitKey:initKeyRecord.id initKeyRecord:initKeyRecord];
        
        
        NSData* test = [initKeyRecord.keyPair publicKey];
        
        [alicePublicInitKeys addObject: [[CryptoPublicInitKey alloc] initWithIdentifier:initKeyRecord.id publicKey:test]];
    }];
    
    self.aliceInitKeysBundle = [[CryptoInitKeysBundle alloc] initWithSignedInitKeyId:self.aliceStore.localSignedInitKeyId
                                                                                                 deviceId:self.aliceStore.deviceId
                                                                                                   userId:self.aliceStore.userId
                                                                                       signedInitKeyPublic:self.aliceStore.localSignedInitKey.keyPair.publicKey
                                                                                    signedInitKeySignature:self.aliceStore.localSignedInitKey.signature
                                                                                              identityKey:self.aliceStore.identityKeyPair.publicKey
                                                                                                  initKeys:alicePublicInitKeys.copy];
    
    NSMutableArray *bobPublicInitKeys = @[].mutableCopy;
    [[TUNMulticastKitCryptoInMemoryStore initKeysWithStartingId:1 count:20] enumerateObjectsUsingBlock:^(InitKeyRecord *initKeyRecord, NSUInteger idx, BOOL *stop) {
        [self.bobStore storeInitKey:initKeyRecord.id initKeyRecord:initKeyRecord];
        [bobPublicInitKeys addObject: [[CryptoPublicInitKey alloc] initWithIdentifier:initKeyRecord.id publicKey:[initKeyRecord.keyPair publicKey]]];
    }];
    self.bobInitKeysBundle = [[CryptoInitKeysBundle alloc] initWithSignedInitKeyId:self.bobStore.localSignedInitKeyId
                                                                                               deviceId:self.bobStore.deviceId
                                                                                                 userId:self.bobStore.userId
                                                                                     signedInitKeyPublic:self.bobStore.localSignedInitKey.keyPair.publicKey
                                                                                  signedInitKeySignature:self.bobStore.localSignedInitKey.signature
                                                                                            identityKey:self.bobStore.identityKeyPair.publicKey
                                                                                                initKeys:bobPublicInitKeys.copy];
    
    NSMutableArray *bob2PublicInitKeys = @[].mutableCopy;
    [[TUNMulticastKitCryptoInMemoryStore initKeysWithStartingId:1 count:20] enumerateObjectsUsingBlock:^(InitKeyRecord *initKeyRecord, NSUInteger idx, BOOL *stop) {
        [self.bob2Store storeInitKey:initKeyRecord.id initKeyRecord:initKeyRecord];
        [bob2PublicInitKeys addObject: [[CryptoPublicInitKey alloc] initWithIdentifier:initKeyRecord.id publicKey:[initKeyRecord.keyPair publicKey]]];
    }];
    self.bob2InitKeysBundle = [[CryptoInitKeysBundle alloc] initWithSignedInitKeyId:self.bob2Store.localSignedInitKeyId
                                                                           deviceId:self.bob2Store.deviceId
                                                                             userId:self.bob2Store.userId
                                                                 signedInitKeyPublic:self.bob2Store.localSignedInitKey.keyPair.publicKey
                                                              signedInitKeySignature:self.bob2Store.localSignedInitKey.signature
                                                                        identityKey:self.bob2Store.identityKeyPair.publicKey
                                                                            initKeys:bob2PublicInitKeys.copy];
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testTwoSendersPickedTheSameInitKey {
    // Remove all Alice initKeys
    NSArray<InitKeyRecord *> *initKeys = [self.aliceStore loadInitKeys];
    for (InitKeyRecord *initKeyRecord in initKeys) {
        [self.aliceStore removeInitKey:initKeyRecord.id];
    }
    
    // Generate 1 initKey for Alice
    NSArray *aliceInitKeys = [TUNMulticastKitCryptoInMemoryStore initKeysWithStartingId:1 count:1];
    
    XCTAssertTrue(aliceInitKeys.count == 1, "Alice should have only one initKey");
    
    InitKeyRecord *aliceInitKeyRecord = (InitKeyRecord*)aliceInitKeys.firstObject;
    [self.aliceStore storeInitKey:aliceInitKeyRecord.id initKeyRecord:aliceInitKeyRecord];
    
    // Generate initKey bundle with 1 initKey
    
    CryptoInitKeysBundle *aliceInitKeysBundle = [[CryptoInitKeysBundle alloc] initWithSignedInitKeyId:self.aliceStore.localSignedInitKeyId
                                                                                                deviceId:self.aliceStore.deviceId
                                                                                                  userId:self.aliceStore.userId
                                                                                      signedInitKeyPublic:self.aliceStore.localSignedInitKey.keyPair.publicKey
                                                                                   signedInitKeySignature:self.aliceStore.localSignedInitKey.signature
                                                                                             identityKey:self.aliceStore.identityKeyPair.publicKey
                                                                                                 initKeys:@[[[CryptoPublicInitKey alloc]initWithIdentifier:aliceInitKeyRecord.id publicKey: [aliceInitKeyRecord.keyPair publicKey]]]];

    NSError *error;

    // Bob sends msg 1 to Alice, picks the only initKey Alice have
    NSString *msg1Text = @"MSG 1";
    NSString *msg1IV =  [[CryptoToolkit.sharedInstance.configuration.symmetricCipher generateIV] base64EncodedStringWithOptions:0];
    NSString *msg1EncryptionKey = [[CryptoToolkit.sharedInstance.configuration.symmetricCipher generateKey] base64EncodedStringWithOptions:0];
    MultiCastMessageHeader *bobToAliceMSG1Header = [self.bobMulticastKit messageHeaderDictionaryWithSenderId:self.bobStore.userId
                                                                              encryptionInitializationVector:msg1IV
                                                                                               encryptionKey:msg1EncryptionKey
                                                                                   recipientsInitKeysBundles:@[aliceInitKeysBundle]
                                                                                                       error:&error];
    
    NSString *msg1EncryptedPayload = [self.bob2MulticastKit messagePayloadWithText:msg1Text
                                                    encryptionInitializationVector:msg1IV
                                                                     encryptionKey:msg1EncryptionKey];
    XCTAssertNil(error);

    // Bob2 sends msg 1_1 to Alice, picks the same initKey, the only initKey Alice have
    NSString *msg1_1Text = @"MSG 1_1";
    NSString *msg1_1IV =  [[CryptoToolkit.sharedInstance.configuration.symmetricCipher generateIV] base64EncodedStringWithOptions:0];
    NSString *msg1_1EncryptionKey = [[CryptoToolkit.sharedInstance.configuration.symmetricCipher generateKey] base64EncodedStringWithOptions:0];
    MultiCastMessageHeader *bob2ToAliceMSG1_1Header = [self.bob2MulticastKit messageHeaderDictionaryWithSenderId:self.bob2Store.userId
                                                                                  encryptionInitializationVector:msg1_1Text
                                                                                                   encryptionKey:msg1_1EncryptionKey
                                                                                       recipientsInitKeysBundles:@[aliceInitKeysBundle]
                                                                                                           error:&error];
    XCTAssertNil(error);
    
    NSString *msg1_1EncryptedPayload = [self.bob2MulticastKit messagePayloadWithText:msg1_1Text
                                                      encryptionInitializationVector:msg1_1IV
                                                                       encryptionKey:msg1_1EncryptionKey];
    
    // Alice processes msg 1 from Bob
    NSError *msg1ProcessingError = nil;
    id result = [self.aliceMulticastKit processMessageWithMessageHeader:bobToAliceMSG1Header
                                                       encryptedPayload:msg1EncryptedPayload
                                                                  error:&msg1ProcessingError];
    XCTAssertNil(msg1ProcessingError);
    
    // Alice processes msg 1_1 from Bob2 who uses the same initKey as Bob previously used, it should generate a decryption error
    NSError *msg1_1ProcessingError = nil;
    result = [self.aliceMulticastKit processMessageWithMessageHeader:bob2ToAliceMSG1_1Header
                                                    encryptedPayload:msg1_1EncryptedPayload
                                                               error:&msg1_1ProcessingError];
    
    
    XCTAssertEqualObjects(msg1_1ProcessingError.domain, MulticastError.domain);
    XCTAssertEqual(msg1_1ProcessingError.code, MulticastError.initKeyFromMessageNotFoundErrorCode);
    
    /*
     * Recovery
     */
    
    // Alice sends msg 2 to Bob2
    NSString *msg2Text = @"MSG 2";
    NSString *msg2IV =  [[CryptoToolkit.sharedInstance.configuration.symmetricCipher generateIV] base64EncodedStringWithOptions:0];
    NSString *msg2EncryptionKey = [[CryptoToolkit.sharedInstance.configuration.symmetricCipher generateKey] base64EncodedStringWithOptions:0];
    MultiCastMessageHeader *aliceToBob2MSG2Header = [self.aliceMulticastKit messageHeaderDictionaryWithSenderId:self.aliceStore.userId
                                                                                encryptionInitializationVector:msg2IV
                                                                                                 encryptionKey:msg2EncryptionKey
                                                                                     recipientsInitKeysBundles:@[self.bob2InitKeysBundle]
                                                                                                         error:&error];
    XCTAssertNil(error);
    
    NSString *msg2EncryptedPayload = [self.aliceMulticastKit messagePayloadWithText:msg2Text
                                                     encryptionInitializationVector:msg2IV
                                                                      encryptionKey:msg2EncryptionKey];
    
    
    // Bob2 processes msg 2 from Alice
    NSError *msg2ProcessingError = nil;
    MulticastMessageProcessingResult *msg2ProcessingResult = [self.bob2MulticastKit processMessageWithMessageHeader:aliceToBob2MSG2Header
                                                                                                   encryptedPayload:msg2EncryptedPayload
                                                                                                              error:&msg2ProcessingError];
    XCTAssertNil(msg2ProcessingError);
    NSString *msg2DecryptedPayload = msg2ProcessingResult.decryptedPayload;
    XCTAssertTrue([msg2DecryptedPayload isEqualToString:@"MSG 2"]); // Bob2 can receive messages from Alice
    
    // Bob2 sends msg 3 to Alice
    NSString *msg3Text = @"MSG 3";
    NSString *msg3IV =  [[CryptoToolkit.sharedInstance.configuration.symmetricCipher generateIV] base64EncodedStringWithOptions:0];
    NSString *msg3EncryptionKey = [[CryptoToolkit.sharedInstance.configuration.symmetricCipher generateKey] base64EncodedStringWithOptions:0];
    MultiCastMessageHeader *bob2ToAliceMSG3Header = [self.bob2MulticastKit messageHeaderDictionaryWithSenderId:self.bob2Store.userId
                                                                                encryptionInitializationVector:msg3IV
                                                                                                 encryptionKey:msg3EncryptionKey
                                                                                     recipientsInitKeysBundles:@[aliceInitKeysBundle]
                                                                                                         error:&error];
    XCTAssertNil(error);
    
    NSString *msg3EncryptedPayload = [self.bob2MulticastKit messagePayloadWithText:msg3Text
                                                    encryptionInitializationVector:msg3IV
                                                                     encryptionKey:msg3EncryptionKey];
    
    // Alice processes msg 3 from Bob
    NSError *msg3ProcessingError = nil;
    MulticastMessageProcessingResult *msg3ProcessingResult = [self.aliceMulticastKit processMessageWithMessageHeader:bob2ToAliceMSG3Header
                                                                                                    encryptedPayload:msg3EncryptedPayload
                                                                                                               error:&msg3ProcessingError];
    
    XCTAssertNil(msg3ProcessingError);
    NSString *msg3DecryptedPayload = msg3ProcessingResult.decryptedPayload;
    XCTAssertTrue([msg3DecryptedPayload isEqualToString:@"MSG 3"]); // Alice can receive messages from Bob2
}

- (void)testTopUpInitKeysNotGeneratingTheSameInitKeyIdAsExcludedId {
    NSArray<InitKeyRecord *> *initKeys = [self.aliceStore loadInitKeys];
    NSUInteger initialNumberOfInitKeys = initKeys.count;
    
    long maxInitKeyId = 0;
    for (InitKeyRecord *initKeyRecord in initKeys) {
        if (initKeyRecord.id > maxInitKeyId) {
            maxInitKeyId = initKeyRecord.id;
        }
    }
    [self.aliceStore removeInitKey:maxInitKeyId];// use initKey with max id
    
    BOOL createdNewInitKeys = false;
    
    NSArray *currentInitKeysRecords = [((TUNMulticastKitCryptoInMemoryStore*)self.aliceStore) topUpInitKeysTo:initialNumberOfInitKeys
                                                         excludedIds:@[@(maxInitKeyId)]
                                                   createdNewInitKeys:&createdNewInitKeys];
    BOOL foundExcludedIdInGeneratedInitKeys = NO;
    for (InitKeyRecord *initKeyRecord in currentInitKeysRecords) {
        if (initKeyRecord.id == maxInitKeyId) {
            foundExcludedIdInGeneratedInitKeys = YES;
            break;
        }
    }
    XCTAssertFalse(foundExcludedIdInGeneratedInitKeys);
}

- (void)testOutOfOrderInvalidSessions1Full
{
    /*
        It makes a difference if session records are serialized during storeSession:deviceId:session: or they're not.
        initWithCoder: method in SessionRecord set's session's self.fresh = false
        if sessionRecord is not fresh during processInitKeyBundle (message creation), it will not archive current session with recipient device, but will override it with a new one. Old session will be lost.
     */
    
    XCTAssertFalse([self.aliceStore containsSession:self.bobStore.userId deviceId:self.bobStore.deviceId], @"Alice shouldn't have a session with Bob");
    XCTAssertFalse([self.bobStore containsSession:self.aliceStore.userId deviceId:self.aliceStore.deviceId], @"Bob shouldn't have a session with Alice");
    
    NSError *error;
    
    // MSG1 --- Alice sends MSG1 to Bob
    
    NSString *msg1Text = @"MSG 1";

    NSString *msg1IV = [[CryptoToolkit.sharedInstance.configuration.symmetricCipher generateIV] base64EncodedStringWithOptions:0];
    NSString *msg1EncryptionKey = [[CryptoToolkit.sharedInstance.configuration.symmetricCipher generateKey] base64EncodedStringWithOptions:0];
    MultiCastMessageHeader *aliceToBobMSG1Header = [self.aliceMulticastKit messageHeaderDictionaryWithSenderId:self.aliceStore.userId
                                                                  encryptionInitializationVector:msg1IV
                                                                                   encryptionKey:msg1EncryptionKey
                                                                        recipientsInitKeysBundles:@[self.aliceInitKeysBundle, self.bobInitKeysBundle]
                                                                                           error:&error];
    NSString *msg1EncryptedPayload = [self.aliceMulticastKit messagePayloadWithText:msg1Text
                                                 encryptionInitializationVector:msg1IV
                                                                  encryptionKey:msg1EncryptionKey];
    
    
    NSMutableDictionary<NSString*, NSDictionary*> *aliceSessionRecords = [((TUNMulticastKitCryptoInMemoryStore*)self.aliceMulticastKit.cryptoStore) sessionRecords];
    XCTAssert(aliceSessionRecords.count == 2, @"Alice should have 2 sessions from 2 initKey secret messages sent to Bob and to Alice");
    
    SessionRecord *aliceSessionRecordWithAlice = [NSKeyedUnarchiver unarchiveObjectWithData:aliceSessionRecords[self.aliceStore.userId].allValues.firstObject];
    SessionRecord *aliceSessionRecordWithBob = [NSKeyedUnarchiver unarchiveObjectWithData:aliceSessionRecords[self.bobStore.userId].allValues.firstObject];
    XCTAssert(aliceSessionRecordWithAlice.previousStates.count == 0, @"Alice should have only 1 session state in a session with Alice");
    XCTAssert(aliceSessionRecordWithBob.previousStates.count == 0, @"Alice should have only 1 session state in a session with Bob");

    
    // MSG2 --- Bob sends MSG2 to Alice
    
    NSString *msg2Text = @"MSG 2";
    
    NSString *msg2IV = [[CryptoToolkit.sharedInstance.configuration.symmetricCipher generateIV] base64EncodedStringWithOptions:0];
    NSString *msg2EncryptionKey = [[CryptoToolkit.sharedInstance.configuration.symmetricCipher generateKey] base64EncodedStringWithOptions:0];
    MultiCastMessageHeader *bobToAliceMSG2Header = [self.bobMulticastKit messageHeaderDictionaryWithSenderId:self.bobStore.userId
                                                              encryptionInitializationVector:msg2IV
                                                                               encryptionKey:msg2EncryptionKey
                                                                    recipientsInitKeysBundles:@[self.aliceInitKeysBundle, self.bobInitKeysBundle]
                                                                                       error:&error];
    NSString *msg2EncryptedPayload = [self.aliceMulticastKit messagePayloadWithText:msg2Text
                                                 encryptionInitializationVector:msg2IV
                                                                  encryptionKey:msg2EncryptionKey];
    
    NSMutableDictionary<NSString*, NSDictionary*> *bobSessionRecords = [((TUNMulticastKitCryptoInMemoryStore*)self.bobMulticastKit.cryptoStore) sessionRecords];
    XCTAssert(bobSessionRecords.count == 2, @"Bob should have 2 sessions from 2 initKey secret messages sent to Bob and to Alice");
    
    SessionRecord *bobSessionRecordWithBob = [NSKeyedUnarchiver unarchiveObjectWithData:aliceSessionRecords[self.bobStore.userId].allValues.firstObject];
    SessionRecord *bobSessionRecordWithAlice = [NSKeyedUnarchiver unarchiveObjectWithData:aliceSessionRecords[self.aliceStore.userId].allValues.firstObject];
    XCTAssert(bobSessionRecordWithBob.previousStates.count == 0, @"Bob should have only 1 session state in session with Bob");
    XCTAssert(bobSessionRecordWithAlice.previousStates.count == 0, @"Bob should have only 1 session state in session with Alice");
    
    // MSG2 --- Alice receives MSG2 from Bob
    
    MulticastMessageProcessingResult *messageProcessingResult = [self.aliceMulticastKit processMessageWithMessageHeader:bobToAliceMSG2Header
                                                                                                     encryptedPayload:msg2EncryptedPayload
                                                                                                                error:&error];
    XCTAssertNil(error, @"There was an error during decryption");
    
    XCTAssert([messageProcessingResult.decryptedPayload isEqualToString:msg2Text], @"Message payload wasn't properly decrypted");
    XCTAssert([messageProcessingResult.encryptionInitializationVector isEqualToString:msg2IV], @"Returned improper initialization vector");
    XCTAssert([messageProcessingResult.encryptionKey isEqualToString:msg2EncryptionKey], @"Returned improper encryption key");
    
    aliceSessionRecords = [((TUNMulticastKitCryptoInMemoryStore*)self.aliceMulticastKit.cryptoStore) sessionRecords];
    XCTAssert(aliceSessionRecords.count == 2, @"Bob should have 2 sessions from 2 initKey secret messages sent to Bob and to Alice");
    
    aliceSessionRecordWithAlice = [NSKeyedUnarchiver unarchiveObjectWithData:aliceSessionRecords[self.aliceStore.userId].allValues.firstObject];
    aliceSessionRecordWithBob = [NSKeyedUnarchiver unarchiveObjectWithData:aliceSessionRecords[self.bobStore.userId].allValues.firstObject];
    XCTAssert(aliceSessionRecordWithAlice.previousStates.count == 0, @"Alice should have only 1 session state in session with Alice");
    XCTAssert(aliceSessionRecordWithBob.previousStates.count == 1, @"Alice should have  2 session states in session with Bob");
    
    // MSG1 --- Bob receives MSG1 from Alice
    
    messageProcessingResult = [self.bobMulticastKit processMessageWithMessageHeader:aliceToBobMSG1Header
                                                                  encryptedPayload:msg1EncryptedPayload
                                                                             error:&error];
    
    XCTAssertNil(error, @"There was an error during decryption");
    
    XCTAssert([messageProcessingResult.decryptedPayload isEqualToString:msg1Text], @"Message payload wasn't properly decrypted");
    XCTAssert([messageProcessingResult.encryptionInitializationVector isEqualToString:msg1IV], @"Returned improper initialization vector");
    XCTAssert([messageProcessingResult.encryptionKey isEqualToString:msg1EncryptionKey], @"Returned improper encryption key");
    
    bobSessionRecords = [((TUNMulticastKitCryptoInMemoryStore*)self.bobMulticastKit.cryptoStore) sessionRecords];
    XCTAssert(bobSessionRecords.count == 2, @"Bob should have 2 sessions, one with Bob, 2 with Alice");
    
    bobSessionRecordWithBob = [NSKeyedUnarchiver unarchiveObjectWithData:bobSessionRecords[self.bobStore.userId].allValues.firstObject];
    bobSessionRecordWithAlice = [NSKeyedUnarchiver unarchiveObjectWithData:bobSessionRecords[self.aliceStore.userId].allValues.firstObject];
    XCTAssert(bobSessionRecordWithBob.previousStates.count == 0, @"Bob should have only 1 session state in session with Bob");
    XCTAssert(bobSessionRecordWithAlice.previousStates.count == 1, @"Bob should have  2 session states in session with Alice");
    
    // MSG3 --- Alice sends MSG3 to Bob
    
    NSString *msg3Text = @"MSG 3";
    
    NSString *msg3IV = [[CryptoToolkit.sharedInstance.configuration.symmetricCipher generateIV] base64EncodedStringWithOptions:0];
    NSString *msg3EncryptionKey = [[CryptoToolkit.sharedInstance.configuration.symmetricCipher generateKey] base64EncodedStringWithOptions:0];
    MultiCastMessageHeader *aliceToBobMSG3Header = [self.aliceMulticastKit messageHeaderDictionaryWithSenderId:self.aliceStore.userId
                                                                  encryptionInitializationVector:msg3IV
                                                                                   encryptionKey:msg3EncryptionKey
                                                                        recipientsInitKeysBundles:@[self.aliceInitKeysBundle, self.bobInitKeysBundle]
                                                                                           error:&error];
    
    NSString *msg3EncryptedPayload = [self.aliceMulticastKit messagePayloadWithText:msg3Text
                                                 encryptionInitializationVector:msg3IV
                                                                  encryptionKey:msg3EncryptionKey];
    
    // MSG3 --- Bob receives MSG3 from Alice
    messageProcessingResult = [self.bobMulticastKit processMessageWithMessageHeader:aliceToBobMSG3Header
                                                                  encryptedPayload:msg3EncryptedPayload
                                                                             error:&error];
    
    XCTAssertNil(error, @"There was an error during decryption");
    
    XCTAssert([messageProcessingResult.decryptedPayload isEqualToString:msg3Text], @"Message payload wasn't properly decrypted");
    XCTAssert([messageProcessingResult.encryptionInitializationVector isEqualToString:msg3IV], @"Returned improper initialization vector");
    XCTAssert([messageProcessingResult.encryptionKey isEqualToString:msg3EncryptionKey], @"Returned improper encryption key");


    // MSG4 --- Bob sends MSG3 to Alice
    
    NSString *msg4Text = @"MSG 4";
    
    NSString *msg4IV = [[CryptoToolkit.sharedInstance.configuration.symmetricCipher generateIV] base64EncodedStringWithOptions:0];
    NSString *msg4EncryptionKey = [[CryptoToolkit.sharedInstance.configuration.symmetricCipher generateKey] base64EncodedStringWithOptions:0];
    MultiCastMessageHeader *bobToAliceMSG4Header = [self.bobMulticastKit messageHeaderDictionaryWithSenderId:self.bobStore.userId
                                                                encryptionInitializationVector:msg4IV
                                                                                 encryptionKey:msg4EncryptionKey
                                                                      recipientsInitKeysBundles:@[self.aliceInitKeysBundle, self.bobInitKeysBundle]
                                                                                         error:&error];
    
   
    NSString *msg4EncryptedPayload = [self.aliceMulticastKit messagePayloadWithText:msg4Text
                                                 encryptionInitializationVector:msg4IV
                                                                  encryptionKey:msg4EncryptionKey];
    
    // MSG4 --- Alice receives MSG4 from BOB. There shouldn't be NO VALID SESSIONS error.
    messageProcessingResult = [self.aliceMulticastKit processMessageWithMessageHeader:bobToAliceMSG4Header
                                                                    encryptedPayload:msg4EncryptedPayload
                                                                               error:&error];
    
    XCTAssertNil(error, @"There was an error during decryption");
    
    XCTAssert([messageProcessingResult.decryptedPayload isEqualToString:msg4Text], @"Message payload wasn't properly decrypted");
    XCTAssert([messageProcessingResult.encryptionInitializationVector isEqualToString:msg4IV], @"Returned improper initialization vector");
    XCTAssert([messageProcessingResult.encryptionKey isEqualToString:msg4EncryptionKey], @"Returned improper encryption key");
}

- (void)testOutOfOrderInvalidSessions1 {
    NSMutableString *aliceLog = [NSMutableString new];
    NSMutableString *bobLog = [NSMutableString new];
    [aliceLog appendString:@"Init"];
    [bobLog appendString:@"Init"];
    [aliceLog appendFormat:@"\n%@", ((TUNMulticastKitCryptoInMemoryStore*)self.aliceMulticastKit.cryptoStore).debugDescription];
    [bobLog appendFormat:@"\n%@", ((TUNMulticastKitCryptoInMemoryStore*)self.bobMulticastKit.cryptoStore).debugDescription];
    
    // MSG1 --- Alice sends MSG1 to Bob
    MultiCastMessageHeader *msg1Header;
    NSString *msg1Payload;
    [self simulateMsgSendFromAliceToBobWithCreatedMsgHeader:&msg1Header createdMsgPayload:&msg1Payload];
    [aliceLog appendString:@"\nMSG1 --- Alice sent MSG1 to Bob"];
    [bobLog appendString:@"\nMSG1 --- Alice sent MSG1 to Bob"];
    [aliceLog appendFormat:@"\n%@", ((TUNMulticastKitCryptoInMemoryStore*)self.aliceMulticastKit.cryptoStore).debugDescription];
    [bobLog appendFormat:@"\n%@", ((TUNMulticastKitCryptoInMemoryStore*)self.bobMulticastKit.cryptoStore).debugDescription];
    
    // MSG2 --- Bob sends MSG2 to Alice
    MultiCastMessageHeader *msg2Header;
    NSString *msg2Payload;
    [self simulateMsgSendFromBobToAliceWithCreatedMsgHeader:&msg2Header createdMsgPayload:&msg2Payload];
    [aliceLog appendString:@"\nMSG2 --- Bob sent MSG2 to Alice"];
    [bobLog appendString:@"\nMSG2 --- Bob sent MSG2 to Alice"];
    [aliceLog appendFormat:@"\n%@", ((TUNMulticastKitCryptoInMemoryStore*)self.aliceMulticastKit.cryptoStore).debugDescription];
    [bobLog appendFormat:@"\n%@", ((TUNMulticastKitCryptoInMemoryStore*)self.bobMulticastKit.cryptoStore).debugDescription];
    
    // MSG2 --- Alice receives MSG2 from Bob
    [self simulateMsgReceiveWithReceiverMulticastKit:self.aliceMulticastKit receivedHeader:msg2Header receivedPayload:msg2Payload];
    [aliceLog appendString:@"\nMSG2 --- Alice received MSG2 from Bob"];
    [bobLog appendString:@"\nMSG2 --- Alice received MSG2 from Bob"];
    [aliceLog appendFormat:@"\n%@", ((TUNMulticastKitCryptoInMemoryStore*)self.aliceMulticastKit.cryptoStore).debugDescription];
    [bobLog appendFormat:@"\n%@", ((TUNMulticastKitCryptoInMemoryStore*)self.bobMulticastKit.cryptoStore).debugDescription];
    
    // MSG1 --- Bob receives MSG1 from Alice
    [self simulateMsgReceiveWithReceiverMulticastKit:self.bobMulticastKit receivedHeader:msg1Header receivedPayload:msg1Payload];
    [aliceLog appendString:@"\nMSG1 --- Bob received MSG1 from Alice"];
    [bobLog appendString:@"\nMSG1 --- Bob received MSG1 from Alice"];
    [aliceLog appendFormat:@"\n%@", ((TUNMulticastKitCryptoInMemoryStore*)self.aliceMulticastKit.cryptoStore).debugDescription];
    [bobLog appendFormat:@"\n%@", ((TUNMulticastKitCryptoInMemoryStore*)self.bobMulticastKit.cryptoStore).debugDescription];
    
    // MSG3 --- Alice sends MSG3 to Bob
    MultiCastMessageHeader *msg3Header;
    NSString *msg3Payload;
    [self simulateMsgSendFromAliceToBobWithCreatedMsgHeader:&msg3Header createdMsgPayload:&msg3Payload];
    [aliceLog appendString:@"\nMSG3 --- Alice sent MSG3 to Bob"];
    [bobLog appendString:@"\nMSG3 --- Alice sent MSG3 to Bob"];
    [aliceLog appendFormat:@"\n%@", ((TUNMulticastKitCryptoInMemoryStore*)self.aliceMulticastKit.cryptoStore).debugDescription];
    [bobLog appendFormat:@"\n%@", ((TUNMulticastKitCryptoInMemoryStore*)self.bobMulticastKit.cryptoStore).debugDescription];
    
    // MSG3 --- Bob receives MSG3 from Alice
    [self simulateMsgReceiveWithReceiverMulticastKit:self.bobMulticastKit receivedHeader:msg3Header receivedPayload:msg3Payload];
    [aliceLog appendString:@"\nMSG3 --- Bob received MSG3 from Alice"];
    [bobLog appendString:@"\nMSG3 --- Bob received MSG3 from Alice"];
    [aliceLog appendFormat:@"\n%@", ((TUNMulticastKitCryptoInMemoryStore*)self.aliceMulticastKit.cryptoStore).debugDescription];
    [bobLog appendFormat:@"\n%@", ((TUNMulticastKitCryptoInMemoryStore*)self.bobMulticastKit.cryptoStore).debugDescription];
    
    // MSG4 --- Bob sends MSG4 to Alice
    MultiCastMessageHeader *msg4Header;
    NSString *msg4Payload;
    [self simulateMsgSendFromBobToAliceWithCreatedMsgHeader:&msg4Header createdMsgPayload:&msg4Payload];
    [aliceLog appendString:@"\nMSG4 --- Bob sent MSG4 to Alice"];
    [bobLog appendString:@"\nMSG4 --- Bob sent MSG4 to Alice"];
    [aliceLog appendFormat:@"\n%@", ((TUNMulticastKitCryptoInMemoryStore*)self.aliceMulticastKit.cryptoStore).debugDescription];
    [bobLog appendFormat:@"\n%@", ((TUNMulticastKitCryptoInMemoryStore*)self.bobMulticastKit.cryptoStore).debugDescription];
    
    // MSG4 --- Alice receives MSG4 from BOB. There shouldn't be NO VALID SESSIONS error.
    [self simulateMsgReceiveWithReceiverMulticastKit:self.aliceMulticastKit receivedHeader:msg4Header receivedPayload:msg4Payload];
    [aliceLog appendString:@"\nMSG4 --- Alice receives MSG4 from BOB."];
    [bobLog appendString:@"\nMSG4 --- Alice receives MSG4 from BOB."];
    [aliceLog appendFormat:@"\n%@", ((TUNMulticastKitCryptoInMemoryStore*)self.aliceMulticastKit.cryptoStore).debugDescription];
    [bobLog appendFormat:@"\n%@", ((TUNMulticastKitCryptoInMemoryStore*)self.bobMulticastKit.cryptoStore).debugDescription];
    
    [aliceLog appendString:@"\nEND"];
    [bobLog appendString:@"\nEND"];
    
    NSLog(@"%@", aliceLog);
    NSLog(@"%@", bobLog);
}


- (void)testOutOfOrderInvalidSessions11 {
    // MSG1 --- Alice sends MSG1 to Bob
    MultiCastMessageHeader *msg1Header;
    NSString *msg1Payload;
    [self simulateMsgSendFromAliceToBobWithCreatedMsgHeader:&msg1Header createdMsgPayload:&msg1Payload];
    
    // MSG11 --- Alice sends MSG11 to Bob
    MultiCastMessageHeader *msg11Header;
    NSString *msg11Payload;
    [self simulateMsgSendFromAliceToBobWithCreatedMsgHeader:&msg11Header createdMsgPayload:&msg11Payload];
    
    // MSG2 --- Bob sends MSG2 to Alice
    MultiCastMessageHeader *msg2Header;
    NSString *msg2Payload;
    [self simulateMsgSendFromBobToAliceWithCreatedMsgHeader:&msg2Header createdMsgPayload:&msg2Payload];
    
    // MSG2 --- Alice receives MSG2 from Bob
    [self simulateMsgReceiveWithReceiverMulticastKit:self.aliceMulticastKit receivedHeader:msg2Header receivedPayload:msg2Payload];
    
    // MSG1 --- Bob receives MSG1 from Alice
    [self simulateMsgReceiveWithReceiverMulticastKit:self.bobMulticastKit receivedHeader:msg1Header receivedPayload:msg1Payload];
    
    // MSG11 --- Bob receives MSG11 from Alice
    [self simulateMsgReceiveWithReceiverMulticastKit:self.bobMulticastKit receivedHeader:msg11Header receivedPayload:msg11Payload];
    
    // MSG3 --- Alice sends MSG3 to Bob
    MultiCastMessageHeader *msg3Header;
    NSString *msg3Payload;
    [self simulateMsgSendFromAliceToBobWithCreatedMsgHeader:&msg3Header createdMsgPayload:&msg3Payload];
    
    // MSG3 --- Bob receives MSG3 from Alice
    [self simulateMsgReceiveWithReceiverMulticastKit:self.bobMulticastKit receivedHeader:msg3Header receivedPayload:msg3Payload];
    
    // MSG4 --- Bob sends MSG4 to Alice
    MultiCastMessageHeader *msg4Header;
    NSString *msg4Payload;
    [self simulateMsgSendFromBobToAliceWithCreatedMsgHeader:&msg4Header createdMsgPayload:&msg4Payload];
    
    // MSG4 --- Alice receives MSG4 from BOB. There shouldn't be NO VALID SESSIONS error.
    [self simulateMsgReceiveWithReceiverMulticastKit:self.aliceMulticastKit receivedHeader:msg4Header receivedPayload:msg4Payload];
    
    NSLog(@"a");
}

- (void)testOutOfOrderInvalidSessions2 {
    // MSG1 --- Alice sends MSG1 to Bob
    MultiCastMessageHeader *msg1Header;
    NSString *msg1Payload;
    [self simulateMsgSendFromAliceToBobWithCreatedMsgHeader:&msg1Header createdMsgPayload:&msg1Payload];
    
    // MSG2 --- Alice sends MSG2 to Bob
    MultiCastMessageHeader *msg2Header;
    NSString *msg2Payload;
    [self simulateMsgSendFromAliceToBobWithCreatedMsgHeader:&msg2Header createdMsgPayload:&msg2Payload];
    
    // MSG2 --- Bob receives MSG2 from Alice
    [self simulateMsgReceiveWithReceiverMulticastKit:self.bobMulticastKit receivedHeader:msg2Header receivedPayload:msg2Payload];
    
    // MSG1 --- Bob receives MSG1 from Alice
    [self simulateMsgReceiveWithReceiverMulticastKit:self.bobMulticastKit receivedHeader:msg2Header receivedPayload:msg2Payload];
    
    // MSG3 --- Bob sends MSG3 to Alice
    MultiCastMessageHeader *msg3Header;
    NSString *msg3Payload;
    [self simulateMsgSendFromBobToAliceWithCreatedMsgHeader:&msg3Header createdMsgPayload:&msg3Payload];
    
    // MSG3 --- Alice receives MSG3 from Bob
    [self simulateMsgReceiveWithReceiverMulticastKit:self.aliceMulticastKit receivedHeader:msg3Header receivedPayload:msg3Payload];
    
    // MSG4 --- Alice sends MSG4 to Bob
    MultiCastMessageHeader *msg4Header;
    NSString *msg4Payload;
    [self simulateMsgSendFromAliceToBobWithCreatedMsgHeader:&msg4Header createdMsgPayload:&msg4Payload];
    
    // MSG4 --- Bob receives MSG4 from Alice
    [self simulateMsgReceiveWithReceiverMulticastKit:self.bobMulticastKit receivedHeader:msg4Header receivedPayload:msg4Payload];
}

- (void)testOutOfOrderInvalidSessions3 {
    // MSG1 --- Alice sends MSG1 to Bob
    MultiCastMessageHeader *msg1Header;
    NSString *msg1Payload;
    [self simulateMsgSendFromAliceToBobWithCreatedMsgHeader:&msg1Header createdMsgPayload:&msg1Payload];
    
    // MSG2 --- Alice sends MSG2 to Bob
    MultiCastMessageHeader *msg2Header;
    NSString *msg2Payload;
    [self simulateMsgSendFromAliceToBobWithCreatedMsgHeader:&msg2Header createdMsgPayload:&msg2Payload];
    
    // MSG3 --- Bob sends MSG3 to Alice
    MultiCastMessageHeader *msg3Header;
    NSString *msg3Payload;
    [self simulateMsgSendFromBobToAliceWithCreatedMsgHeader:&msg3Header createdMsgPayload:&msg3Payload];
    
    // MSG2 --- Bob receives MSG2 from Alice
    [self simulateMsgReceiveWithReceiverMulticastKit:self.bobMulticastKit receivedHeader:msg2Header receivedPayload:msg2Payload];

    // MSG3 --- Alice receives MSG3 from Bob
    [self simulateMsgReceiveWithReceiverMulticastKit:self.aliceMulticastKit receivedHeader:msg3Header receivedPayload:msg3Payload];
    
    // MSG1 --- Bob receives MSG1 from Alice
    [self simulateMsgReceiveWithReceiverMulticastKit:self.bobMulticastKit receivedHeader:msg1Header receivedPayload:msg1Payload];
    
    // MSG4 --- Bob sends MSG4 to Alice
    MultiCastMessageHeader *msg4Header;
    NSString *msg4Payload;
    [self simulateMsgSendFromBobToAliceWithCreatedMsgHeader:&msg4Header createdMsgPayload:&msg4Payload];
    
    // MSG4 --- Alice receives MSG4 from Bob
    [self simulateMsgReceiveWithReceiverMulticastKit:self.aliceMulticastKit receivedHeader:msg4Header receivedPayload:msg4Payload];
    
    // MSG5 --- Alice sends MSG5 to Bob
    MultiCastMessageHeader *msg5Header;
    NSString *msg5Payload;
    [self simulateMsgSendFromAliceToBobWithCreatedMsgHeader:&msg5Header createdMsgPayload:&msg5Payload];
    
    // MSG5 --- Bob receives MSG5 from Alice
    [self simulateMsgReceiveWithReceiverMulticastKit:self.bobMulticastKit receivedHeader:msg5Header receivedPayload:msg5Payload];
}

#pragma mark - Simulating Msg Sending and Receiving

- (void)simulateMsgSendFromAliceToBobWithCreatedMsgHeader:(MultiCastMessageHeader**)createdMsgHeader
                                        createdMsgPayload:(NSString**)createdMsgPayload {
    CryptoInitKeysBundle *aliceInitKeysBundleForThisMessage = [self generateAliceKeyBundleWithNotUsedInitKey];
    CryptoInitKeysBundle *bobInitKeysBundleForThisMessage = [self generateBobKeyBundleWithNotUsedInitKey];
    
    [self simulateSendMsgWithSenderStore:self.aliceStore
                     senderInitKeyBundle:aliceInitKeysBundleForThisMessage
                      senderMulticastKit:self.aliceMulticastKit
                  recipientInitKeyBundle:bobInitKeysBundleForThisMessage
                        createdMsgHeader:createdMsgHeader
                       createdMsgPayload:createdMsgPayload];
}

- (void)simulateMsgSendFromBobToAliceWithCreatedMsgHeader:(MultiCastMessageHeader**)createdMsgHeader
                                        createdMsgPayload:(NSString**)createdMsgPayload {
    CryptoInitKeysBundle *aliceInitKeysBundleForThisMessage = [self generateAliceKeyBundleWithNotUsedInitKey];
    CryptoInitKeysBundle *bobInitKeysBundleForThisMessage = [self generateBobKeyBundleWithNotUsedInitKey];
    
    [self simulateSendMsgWithSenderStore:self.bobStore
                     senderInitKeyBundle:bobInitKeysBundleForThisMessage
                      senderMulticastKit:self.bobMulticastKit
                  recipientInitKeyBundle:aliceInitKeysBundleForThisMessage
                        createdMsgHeader:createdMsgHeader
                       createdMsgPayload:createdMsgPayload];
}

- (void)simulateSendMsgWithSenderStore:(TUNMulticastKitCryptoInMemoryStore*)senderStore
                    senderInitKeyBundle:(CryptoInitKeysBundle*)senderInitKeyBundle
                        senderMulticastKit:(MultiCastKit*)senderMulticastKit
                 recipientInitKeyBundle:(CryptoInitKeysBundle*)recipientInitKeyBundle
                      createdMsgHeader:(MultiCastMessageHeader**)createdMsgHeader
                     createdMsgPayload:(NSString**)createdMsgPayload {
    NSError *error;
    
    NSString *msgText = [[CryptoToolkit.sharedInstance.configuration.symmetricCipher generateKey] base64EncodedStringWithOptions:0];
    
    NSString *msgIV = [[CryptoToolkit.sharedInstance.configuration.symmetricCipher generateIV] base64EncodedStringWithOptions:0];
    NSString *msgEncryptionKey = [[CryptoToolkit.sharedInstance.configuration.symmetricCipher generateKey] base64EncodedStringWithOptions:0];
    
    *createdMsgHeader = [senderMulticastKit messageHeaderDictionaryWithSenderId:senderStore.userId
                                             encryptionInitializationVector:msgIV
                                                              encryptionKey:msgEncryptionKey
                                                   recipientsInitKeysBundles:@[senderInitKeyBundle, recipientInitKeyBundle]
                                                                      error:&error];
    *createdMsgPayload = [senderMulticastKit messagePayloadWithText:msgText
                                 encryptionInitializationVector:msgIV
                                                  encryptionKey:msgEncryptionKey];
}

- (void)simulateMsgReceiveWithReceiverMulticastKit:(MultiCastKit*)receiverMulticastKit
                                receivedHeader:(MultiCastMessageHeader*)receivedMsgHeader
                               receivedPayload:(NSString*)receivedMsgPayload {
    NSError *error;
    (void)[receiverMulticastKit processMessageWithMessageHeader:receivedMsgHeader
                                        encryptedPayload:receivedMsgPayload
                                                   error:&error];
    
    if (error && ![error isMessageDuplicatedError]) { // old counter
        XCTAssertNil(error, @"There was an error during decryption");
    }
}

- (CryptoInitKeysBundle *)generateAliceKeyBundleWithNotUsedInitKey {
    CryptoPublicInitKey *aliceInitKey = nil;
    NSNumber *aliceInitKeyId = nil;
    NSInteger index = 0;
    do {
        aliceInitKey = self.aliceInitKeysBundle.initKeys[index];
        aliceInitKeyId = @(aliceInitKey.identifier);
        index++;
    } while ([self.usedAliceInitKeyIds containsObject:aliceInitKeyId] || index >= self.aliceInitKeysBundle.initKeys.count);
    
    // Create init key bundle with this init key and pass it for message creation
    CryptoInitKeysBundle *aliceInitKeysBundleForThisMessage =
    [[CryptoInitKeysBundle alloc] initWithSignedInitKeyId:self.aliceStore.localSignedInitKeyId
                                                 deviceId:self.aliceStore.deviceId
                                                   userId:self.aliceStore.userId
                                      signedInitKeyPublic:self.aliceStore.localSignedInitKey.keyPair.publicKey
                                   signedInitKeySignature:self.aliceStore.localSignedInitKey.signature
                                              identityKey:self.aliceStore.identityKeyPair.publicKey
                                                 initKeys:@[aliceInitKey]];
    
    // Add this init key to used alice init keys to avoid `Init key already picked` error for next messages
    [self.usedAliceInitKeyIds addObject:@(aliceInitKey.identifier)];
    
    return aliceInitKeysBundleForThisMessage;
}

- (CryptoInitKeysBundle *)generateBobKeyBundleWithNotUsedInitKey {
    CryptoPublicInitKey *bobInitKey = nil;
    NSNumber *bobInitKeyId = nil;
    NSInteger index = 0;
    do {
        bobInitKey = self.bobInitKeysBundle.initKeys[index];
        bobInitKeyId = @(bobInitKey.identifier);
        index++;
    } while ([self.usedBobInitKeyIds containsObject:bobInitKeyId] || index >= self.bobInitKeysBundle.initKeys.count);
    
    // Create init key bundle with this init key and pass it for message creation
    CryptoInitKeysBundle *bobInitKeysBundleForThisMessage =
    [[CryptoInitKeysBundle alloc] initWithSignedInitKeyId:self.bobStore.localSignedInitKeyId
                                                 deviceId:self.bobStore.deviceId
                                                   userId:self.bobStore.userId
                                      signedInitKeyPublic:self.bobStore.localSignedInitKey.keyPair.publicKey
                                   signedInitKeySignature:self.bobStore.localSignedInitKey.signature
                                              identityKey:self.bobStore.identityKeyPair.publicKey
                                                 initKeys:@[bobInitKey]];
    
    // Add this init key to used alice init keys to avoid `Init key already picked` error for next messages
    [self.usedBobInitKeyIds addObject:@(bobInitKey.identifier)];
    
    return bobInitKeysBundleForThisMessage;
}

#pragma mark -

- (void)testMessageFlow
{
    // Create in-memory stores
    
    XCTAssertFalse([self.aliceStore containsSession:self.bobStore.userId deviceId:self.bobStore.deviceId], @"Alice shouldn't have a session with Bob");
    XCTAssertFalse([self.bobStore containsSession:self.aliceStore.userId deviceId:self.aliceStore.deviceId], @"Bob shouldn't have a session with Alice");
    
    // Create the header for a message from Alice to Bob (i.e. a message that would be sent from Alice's device to Bob)
    NSString *randomInitializationVector = [[CryptoToolkit.sharedInstance.configuration.symmetricCipher generateIV] base64EncodedStringWithOptions:0];
    NSString *randomEncryptionKey = [[CryptoToolkit.sharedInstance.configuration.symmetricCipher generateKey] base64EncodedStringWithOptions:0];
    

    NSError *error;
    MultiCastMessageHeader *messageHeader = [self.aliceMulticastKit messageHeaderDictionaryWithSenderId:self.aliceStore.userId
                                                           encryptionInitializationVector:randomInitializationVector
                                                                            encryptionKey:randomEncryptionKey
                                                                 recipientsInitKeysBundles:@[self.aliceInitKeysBundle, self.bobInitKeysBundle]
                                                                                    error:&error];
    
    // Create message payload for the message from Alice to Bob
    NSString *encryptedPayload = [self.aliceMulticastKit messagePayloadWithText:@"Test message"
                                             encryptionInitializationVector:randomInitializationVector
                                                              encryptionKey:randomEncryptionKey];
    
    XCTAssert([self.aliceStore containsSession:self.bobStore.userId deviceId:self.bobStore.deviceId], @"Alice shouldn have a session with Bob");
    
    // Decrypt the message
    MulticastMessageProcessingResult *messageProcessingResult = [self.bobMulticastKit processMessageWithMessageHeader:messageHeader
                                                                                                   encryptedPayload:encryptedPayload
                                                                                                              error:&error];
    XCTAssertNil(error, @"There was an error during decryption");
    
    XCTAssert([messageProcessingResult.decryptedPayload isEqualToString:@"Test message"], @"Message payload wasn't properly decrypted");
    XCTAssert([messageProcessingResult.encryptionInitializationVector isEqualToString:randomInitializationVector], @"Returned improper initialization vector");
    XCTAssert([messageProcessingResult.encryptionKey isEqualToString:randomEncryptionKey], @"Returned improper encryption key");
    
    XCTAssert([self.bobStore containsSession:self.aliceStore.userId deviceId:self.aliceStore.deviceId], @"Bob should have a session with Alice");
    
    // Now let's see how encryption and decryption work when sessions are already established
    NSString *newRandomInitializationVector = [[CryptoToolkit.sharedInstance.configuration.symmetricCipher generateIV] base64EncodedStringWithOptions:0];
    NSString *newRandomEncryptionKey = [[CryptoToolkit.sharedInstance.configuration.symmetricCipher generateKey] base64EncodedStringWithOptions:0];
    MultiCastMessageHeader *newMessageHeader = [self.aliceMulticastKit messageHeaderDictionaryWithSenderId:self.aliceStore.userId
                                                              encryptionInitializationVector:newRandomInitializationVector
                                                                               encryptionKey:newRandomEncryptionKey
                                                                    recipientsInitKeysBundles:@[self.aliceInitKeysBundle, self.bobInitKeysBundle]
                                                                                       error:&error];
    
    // Create message payload for the message from Alice to Bob
    NSString *newEncryptedPayload = [self.aliceMulticastKit messagePayloadWithText:@"Another test message"
                                        encryptionInitializationVector:newRandomInitializationVector
                                                         encryptionKey:newRandomEncryptionKey];
    
    // Decrypt the message
    
    messageProcessingResult = [self.bobMulticastKit processMessageWithMessageHeader:newMessageHeader
                                                                                                   encryptedPayload:newEncryptedPayload
                                                                                                              error:&error];
    XCTAssertNil(error, @"There was an error during decryption");
    
    XCTAssert([messageProcessingResult.decryptedPayload isEqualToString:@"Another test message"], @"Message payload wasn't properly decrypted");
    XCTAssert([messageProcessingResult.encryptionInitializationVector isEqualToString:newRandomInitializationVector], @"Returned improper initialization vector");
    XCTAssert([messageProcessingResult.encryptionKey isEqualToString:newRandomEncryptionKey], @"Returned improper encryption key");
    
    
    // Now let's try to prepare a message from Alice to Bob2
    NSString *anotherRandomInitializationVector = [[CryptoToolkit.sharedInstance.configuration.symmetricCipher generateIV] base64EncodedStringWithOptions:0];
    NSString *anotherRandomEncryptionKey = [[CryptoToolkit.sharedInstance.configuration.symmetricCipher generateKey] base64EncodedStringWithOptions:0];
    MultiCastMessageHeader *anotherMessageHeader = [self.aliceMulticastKit messageHeaderDictionaryWithSenderId:self.aliceStore.userId
                                                                  encryptionInitializationVector:anotherRandomInitializationVector
                                                                                   encryptionKey:anotherRandomEncryptionKey
                                                                        recipientsInitKeysBundles:@[self.aliceInitKeysBundle, self.bob2InitKeysBundle]
                                                                                           error:&error];
    
    // Create message payload for the message from Alice to Bob
    NSString *anotherEncryptedPayload = [self.aliceMulticastKit messagePayloadWithText:@"Hi Bob2"
                                                encryptionInitializationVector:anotherRandomInitializationVector
                                                                     encryptionKey:anotherRandomEncryptionKey];
    
    // Decrypt the message
    messageProcessingResult = [self.bob2MulticastKit processMessageWithMessageHeader:anotherMessageHeader
                                                                   encryptedPayload:anotherEncryptedPayload
                                                                              error:&error];
    
    XCTAssertNil(error, @"There was an error during decryption");
    
    XCTAssert([messageProcessingResult.decryptedPayload isEqualToString:@"Hi Bob2"], @"Message payload wasn't properly decrypted");
    XCTAssert([messageProcessingResult.encryptionInitializationVector isEqualToString:anotherRandomInitializationVector], @"Returned improper initialization vector");
    XCTAssert([messageProcessingResult.encryptionKey isEqualToString:anotherRandomEncryptionKey], @"Returned improper encryption key");
}

- (void)testMessageHeaderFormat
{
    NSError *error;
    NSString *randomInitializationVector = [[CryptoToolkit.sharedInstance.configuration.symmetricCipher generateIV] base64EncodedStringWithOptions:0];
    NSString *randomEncryptionKey = [[CryptoToolkit.sharedInstance.configuration.symmetricCipher generateKey] base64EncodedStringWithOptions:0];
    MultiCastMessageHeader *messageHeader = [self.aliceMulticastKit messageHeaderDictionaryWithSenderId:self.aliceStore.userId
                                                           encryptionInitializationVector:randomInitializationVector
                                                                            encryptionKey:randomEncryptionKey
                                                                 recipientsInitKeysBundles:@[self.aliceInitKeysBundle, self.bobInitKeysBundle]
                                                                                    error:&error];

    
    XCTAssert([messageHeader isKindOfClass:[MultiCastMessageHeader class]], @"Message header is not MultiCastMessageHeader");
    
    XCTAssertNotNil(messageHeader.initializationVector, @"Initialization vector not in message header");
    XCTAssertEqualObjects(messageHeader.initializationVector, randomInitializationVector, @"Improper initialization vector in message header");
    
    
    XCTAssertEqual(messageHeader.senderDeviceId, self.aliceStore.deviceId, @"Improper sender device id in message header");
    
    XCTAssertNotNil(messageHeader.senderId, @"Sender id not in message header");
    XCTAssertEqualObjects(messageHeader.senderId, self.aliceStore.userId, @"Improper sender id in message header");
    
    XCTAssertNotNil(messageHeader.keys, @"Keys not in the message header");
    XCTAssert([messageHeader.keys isKindOfClass:[NSArray class]], @"Keys in the message header are not an array");
    XCTAssertEqual([messageHeader.keys count], 2, @"Improper number of keys in the message header (should be one for Alice's initKeys bundle and one for Bob's initKeys bundle");
    
    
    
    
    [messageHeader.keys enumerateObjectsUsingBlock:^(MulticastEncryptedItem *key, NSUInteger idx, BOOL *stop) {
        XCTAssert([key isKindOfClass:[MulticastEncryptedItem class]], @"Key in the message header is not a MultiCastMessageHeaderKey");
        XCTAssert((key.deviceMulticastId == self.aliceStore.deviceId || key.deviceMulticastId == self.bobStore.deviceId), @"Improper device id in a message header key");
        XCTAssertNotNil(key.encryptedValue, @"No encrypted value in the message header key");
    }];
}

@end

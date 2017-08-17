//
//  Copyright © 2017 Tungsten Labs UG. All rights reserved.
//
//  Licensed according to https://www.gnu.org/licenses/gpl-3.0.html
//

#import <XCTest/XCTest.h>
#import <TungstenCrypto/TungstenCrypto-Swift.h>
#import "TUNMulticastKitCryptoInMemoryStore.h"
#import "CryptoLogger.h"
@import TungstenCrypto;

@interface MessageSendingAndReceivingTests : XCTestCase

@property (nonatomic, strong) TUNMulticastKitCryptoInMemoryStore *aliceStore;
@property (nonatomic, strong) MultiCastKit *aliceMulticastKit;
@property (nonatomic, strong) CryptoInitKeysBundle *aliceInitKeysBundle;

@property (nonatomic, strong) TUNMulticastKitCryptoInMemoryStore *bobStore;
@property (nonatomic, strong) MultiCastKit *bobMulticastKit;
@property (nonatomic, strong) CryptoInitKeysBundle *bobInitKeysBundle;

@end

@implementation MessageSendingAndReceivingTests

- (void)setUp {
    [super setUp];
    CryptoConfigurationBuilder* builder = [[CryptoConfigurationBuilder alloc]init];
    [CryptoToolkit.sharedInstance setup:builder.build error:nil];
    
    self.aliceStore = [[TUNMulticastKitCryptoInMemoryStore alloc] initWithUserId:@"Alice" localRegistrationId:@"1" deviceId:@"2"];
    self.bobStore = [[TUNMulticastKitCryptoInMemoryStore alloc] initWithUserId:@"Bob" localRegistrationId:@"3" deviceId:@"4"];
    
    self.aliceMulticastKit = [[MultiCastKit alloc] initWithCryptoStore:self.aliceStore];
    self.bobMulticastKit = [[MultiCastKit alloc] initWithCryptoStore:self.bobStore];
    
    NSMutableArray *alicePublicInitKeys = @[].mutableCopy;
    [[TUNMulticastKitCryptoInMemoryStore initKeysWithStartingId:1 count:1] enumerateObjectsUsingBlock:^(InitKeyRecord *initKeyRecord, NSUInteger idx, BOOL *stop) {
        
        [self.aliceStore storeInitKey:initKeyRecord.id initKeyRecord:initKeyRecord];
        
        NSData *test = [initKeyRecord.keyPair publicKey];
        
        [alicePublicInitKeys addObject: [[CryptoPublicInitKey alloc] initWithIdentifier:initKeyRecord.id publicKey:test]];
    }];
    
    //TODO: CHANGE IT
    self.aliceInitKeysBundle = [[CryptoInitKeysBundle alloc] initWithSignedInitKeyId:self.aliceStore.localSignedInitKeyId
                                                                            deviceId:self.aliceStore.deviceId
                                                                              userId:self.aliceStore.userId
                                                                 signedInitKeyPublic:self.aliceStore.localSignedInitKey.keyPair.publicKey
                                                              signedInitKeySignature:self.aliceStore.localSignedInitKey.signature
                                                                         identityKey:self.aliceStore.identityKeyPair.publicKey
                                                                            initKeys:alicePublicInitKeys.copy];
    
    NSMutableArray *bobPublicInitKeys = @[].mutableCopy;
    [[TUNMulticastKitCryptoInMemoryStore initKeysWithStartingId:1 count:1] enumerateObjectsUsingBlock:^(InitKeyRecord *initKeyRecord, NSUInteger idx, BOOL *stop) {
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
    
}

- (void)tearDown {
    [super tearDown];
}

- (void)testMessageSendingAndReceiving {
    NSError *error;
    
    NSString *msgText = @"MSG 2";
    NSString *encryptionKey = @"YWFhYWJiYmJjY2NjZGRkZGVlZWVmZmZmbm5ubm1tbW0=";
    NSString *IV = @"YWFhYWJiYmJjY2NjZGRkZA==";
    
    // MSG2 --- Bob sends MSG2 to Alice
    
    MultiCastMessageHeader *bobToAliceMSG2Header =
    [self.bobMulticastKit messageHeaderDictionaryWithSenderId:self.bobStore.userId
                               encryptionInitializationVector:IV
                                                encryptionKey:encryptionKey
                                    recipientsInitKeysBundles:@[self.aliceInitKeysBundle]
                                                        error:&error];
    XCTAssertNil(error, @"There should be no error after Bob creates a message to Alice");
    
    NSMutableDictionary<NSString*, NSDictionary*> *bobSessionRecords =
    [((TUNMulticastKitCryptoInMemoryStore*)self.bobMulticastKit.cryptoStore) sessionRecords];
    
    SessionRecord *bobSessionRecordWithAlice =
    [NSKeyedUnarchiver unarchiveObjectWithData:bobSessionRecords[self.aliceStore.userId].allValues.firstObject];
    
    SessionStateInitializedData *bobSessionStateData = bobSessionRecordWithAlice.sessionState.initalizedState;
    
    NSLog(@"bob rootKey %@", bobSessionStateData.rootKey);
    NSLog(@"bob remoteIdentityKey %@", bobSessionStateData.remoteIdentityKey);
    NSLog(@"bob localIdentityKey %@", bobSessionStateData.localIdentityKey);
    NSLog(@"bob senderChainKey %@", bobSessionStateData.senderChainKey);
    
    MessageKeys *bobMessageKeys = [bobSessionStateData.senderChainKey messageKeysAndReturnError:nil];
    NSLog(@"bob messageKeysAndReturnError %@", bobMessageKeys);
    NSLog(@"bob messageKeys.cipherKey %@", bobMessageKeys.cipherKey);
    NSLog(@"bob messageKeys.macKey %@", bobMessageKeys.macKey);
    NSLog(@"bob messageKeys.iv %@", bobMessageKeys.iv);
    NSLog(@"bob messageKeys.index %@", @(bobMessageKeys.index));
    
    NSString *msg2EncryptedPayload = [self.bobMulticastKit messagePayloadWithText:msgText
                                                   encryptionInitializationVector:IV
                                                                    encryptionKey:encryptionKey];
    // MSG2 --- Alice receives MSG2 from Bob
    
    MulticastMessageProcessingResult *messageProcessingResult = [self.aliceMulticastKit processMessageWithMessageHeader:bobToAliceMSG2Header
                                                                                                       encryptedPayload:msg2EncryptedPayload
                                                                                                                  error:&error];
    XCTAssertNil(error, @"There should be no error after Alice processes a message from Bob");
    
    NSMutableDictionary<NSString*, NSDictionary*> *aliceSessionRecords =
    [((TUNMulticastKitCryptoInMemoryStore*)self.aliceMulticastKit.cryptoStore) sessionRecords];
    
    SessionRecord *aliceSessionRecordWithBob =
    [NSKeyedUnarchiver unarchiveObjectWithData:aliceSessionRecords[self.bobStore.userId].allValues.firstObject];

    SessionStateInitializedData *aliceSessionStateData = aliceSessionRecordWithBob.sessionState.initalizedState;
    
    NSLog(@"alice rootKey %@", aliceSessionStateData.rootKey.keyData);
    NSLog(@"alice remoteIdentityKey %@", aliceSessionStateData.remoteIdentityKey);
    NSLog(@"alice localIdentityKey %@", aliceSessionStateData.localIdentityKey);
    NSLog(@"alice senderChainKey %@", aliceSessionStateData.senderChainKey);
    
    MessageKeys *aliceMessageKeys = [aliceSessionStateData.senderChainKey messageKeysAndReturnError:nil];
    NSLog(@"alice messageKeys.cipherKey %@", aliceMessageKeys.cipherKey);
    NSLog(@"alice messageKeys.macKey %@", aliceMessageKeys.macKey);
    NSLog(@"alice messageKeys.iv %@", aliceMessageKeys.iv);
    NSLog(@"alice messageKeys.index %@", @(aliceMessageKeys.index));
    
    msgText = @"MSG3";
    encryptionKey = @"YWFhYWJiYmJjY2NjZGRkZGVlZWVmZmZmbm5ubm1tbW0=";
    IV = @"MTExMTIyMjIzMzMzNDQ0NA==";
    
    // MSG3 --- Alice sends MSG3 to Bob
    
    MultiCastMessageHeader *aliceToBobMSG3Header =
    [self.aliceMulticastKit messageHeaderDictionaryWithSenderId:self.aliceStore.userId
                                 encryptionInitializationVector:IV
                                                  encryptionKey:encryptionKey
                                      recipientsInitKeysBundles:@[self.bobInitKeysBundle]
                                                          error:&error];
    XCTAssertNil(error, @"There should be no error after Alice creates a message to Bob");
    
    NSString *msg3EncryptedPayload = [self.aliceMulticastKit messagePayloadWithText:msgText
                                                     encryptionInitializationVector:IV
                                                                      encryptionKey:encryptionKey];
    // MSG3 --- Bob receives MSG3 from Alice
    
    messageProcessingResult = [self.bobMulticastKit processMessageWithMessageHeader:aliceToBobMSG3Header
                                                                   encryptedPayload:msg3EncryptedPayload
                                                                              error:&error];
    XCTAssertNil(error, @"There should be no error after Bob processes message from Alice");
}

@end

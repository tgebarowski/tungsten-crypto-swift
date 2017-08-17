//
//  Copyright © 2017 Tungsten Labs UG. All rights reserved.
//
//  Licensed according to https://www.gnu.org/licenses/gpl-3.0.html
//

#import <XCTest/XCTest.h>
#import <TungstenCrypto/TungstenCrypto-Swift.h>
#import "NSData+RandomGenerator.h"
@import TungstenCrypto;

@interface SessionStateTests : XCTestCase

@property NSData* dataA;
@property NSData* dataB;
@property NSData* dataC;
@property NSData* dataD;
@property RootKey* rootKeyA;
@property KeyPair* keyPairA;
@property ChainKey* chainKeyA;
@property ChainKey* chainKeyB;
@property ChainKey* chainKeyC;

@property int idA;
@property int idB;
@property int idC;
@property NSString* stringIdC;
@property NSString* stringIdD;

@end

@implementation SessionStateTests

-(void)setUp {
    [super setUp];
    _dataA = [NSData garbageDataWithLength:32];
    _dataB = [NSData garbageDataWithLength:32];
    _dataC = [NSData garbageDataWithLength:32];
    _dataD = [NSData garbageDataWithLength:32];
    
    _rootKeyA = [[RootKey alloc]initWithData:_dataA];
    _keyPairA = [[KeyPair alloc]initWithPrivateKey:_dataA publicKey:_dataB];
    _chainKeyA = [[ChainKey alloc]initWithKey:_dataA index:_idA];
    _chainKeyB = [[ChainKey alloc] initWithKey:_dataB index:_idB];
    _chainKeyC = [[ChainKey alloc] initWithKey:_dataC index:_idC];
    _idA = 0;
    _idB = 1;
    _idC = 2;
    _stringIdC = @"2";
    _stringIdD = @"3";
}

-(void)testInitializer {
    SessionState* state = [[SessionState alloc]init];
    XCTAssertNotNil(state);
    XCTAssertNil(state.aliceBaseKey);
    XCTAssertNil(state.initalizedState.remoteIdentityKey);
    XCTAssertNil(state.initalizedState.localIdentityKey);
    XCTAssertNil(state.initalizedState.rootKey);
    XCTAssertEqual(0, state.version);
    XCTAssertEqual(0, state.previousCounter);
    XCTAssertEqualObjects(@"", state.remoteRegistrationId);
    XCTAssertEqualObjects(@"", state.localRegistrationId);
}

-(void)testEncoding {
    SessionState* state = [[SessionState alloc]init];
    
    state.aliceBaseKey = _dataA;
    state.initalizedState = [[SessionStateInitializedData alloc]initWithRemoteIdentityKey:_dataB localIdentityKey:_dataC rootKey:_rootKeyA sendingChain:[[SendingChain alloc]initWithChainKey:_chainKeyA senderCoreKeyPair:_keyPairA]];
    
    state.version = _idA;
    state.previousCounter = _idB;
    state.remoteRegistrationId = _stringIdC;
    state.localRegistrationId = _stringIdD;
    
    
    [state addReceiverChain:_dataA chainKey:_chainKeyA];
    [state setPendingInitKey:_idA signedInitKeyId:_stringIdC baseKey:_dataA];
    
    NSMutableData* data = [NSMutableData data];
    NSKeyedArchiver* archiver = [[NSKeyedArchiver alloc]initForWritingWithMutableData:data];
    [archiver encodeObject:state forKey: @"key"];
    [archiver finishEncoding];
    
    NSKeyedUnarchiver* unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
    SessionState* unarchivedState = [unarchiver decodeObjectForKey:@"key"];

    XCTAssertEqual(unarchivedState.version, state.version);
    XCTAssertEqual(unarchivedState.previousCounter, state.previousCounter);
    XCTAssertEqualObjects(unarchivedState.remoteRegistrationId, state.remoteRegistrationId);
    XCTAssertEqualObjects(unarchivedState.localRegistrationId, state.localRegistrationId);
    
    XCTAssertEqualObjects(unarchivedState.aliceBaseKey, state.aliceBaseKey);
    XCTAssertEqualObjects(unarchivedState.initalizedState.remoteIdentityKey, state.initalizedState.remoteIdentityKey);
    XCTAssertEqualObjects(unarchivedState.initalizedState.localIdentityKey, state.initalizedState.localIdentityKey);
    XCTAssertEqualObjects(unarchivedState.initalizedState.rootKey.keyData, state.initalizedState.rootKey.keyData);
    
    XCTAssertEqual([unarchivedState.initalizedState senderChainKey].index, [state.initalizedState senderChainKey].index);
    XCTAssertEqualObjects([unarchivedState.initalizedState senderChainKey].key, [state.initalizedState senderChainKey].key);
    
    XCTAssertEqualObjects([unarchivedState pendingInitKey].baseKey, [state pendingInitKey].baseKey);
    
    XCTAssertNotNil([unarchivedState receiverChainKey:_chainKeyA.key]);
    XCTAssertEqualObjects([unarchivedState receiverChainKey:_chainKeyA.key].key, [state receiverChainKey:_chainKeyA.key].key);
}

-(void)testCoping {
    SessionState* state = [[SessionState alloc]init];
    
    state.aliceBaseKey = _dataA;
    state.version = _idA;
    state.previousCounter = _idB;
    state.remoteRegistrationId = _stringIdC;
    state.localRegistrationId = _stringIdD;
    
    state.initalizedState = [[SessionStateInitializedData alloc]initWithRemoteIdentityKey:_dataB
                                                                         localIdentityKey:_dataC
                                                                                  rootKey:_rootKeyA sendingChain:[[SendingChain alloc]initWithChainKey:_chainKeyA senderCoreKeyPair:_keyPairA]];
    
    [state addReceiverChain:_dataA chainKey:_chainKeyA];
    [state setPendingInitKey:_idA signedInitKeyId:_stringIdC baseKey:_dataA];
    
    SessionState* copiedState = [state copy];
    
    XCTAssertEqual(copiedState.version, state.version);
    XCTAssertEqual(copiedState.previousCounter, state.previousCounter);
    XCTAssertEqualObjects(copiedState.remoteRegistrationId, state.remoteRegistrationId);
    XCTAssertEqualObjects(copiedState.localRegistrationId, state.localRegistrationId);
    
    XCTAssertEqualObjects(copiedState.aliceBaseKey, state.aliceBaseKey);
    XCTAssertEqualObjects(copiedState.initalizedState.remoteIdentityKey, state.initalizedState.remoteIdentityKey);
    XCTAssertEqualObjects(copiedState.initalizedState.localIdentityKey, state.initalizedState.localIdentityKey);
    XCTAssertEqualObjects(copiedState.initalizedState.rootKey.keyData, state.initalizedState.rootKey.keyData);
    
    XCTAssertEqual([copiedState.initalizedState senderChainKey].index, [state.initalizedState senderChainKey].index);
    XCTAssertEqualObjects([copiedState.initalizedState senderChainKey].key, [state.initalizedState senderChainKey].key);
    
    XCTAssertEqualObjects([copiedState pendingInitKey].baseKey, [state pendingInitKey].baseKey);
    
    XCTAssertNotNil([copiedState receiverChainKey:_chainKeyA.key]);
    XCTAssertEqualObjects([copiedState receiverChainKey:_chainKeyA.key].key, [state receiverChainKey:_chainKeyA.key].key);
}

-(void)testSetReceiverChainKey {
    SessionState* state = [[SessionState alloc]init];
    
    [state addReceiverChain:_dataA chainKey:_chainKeyA];
    [state addReceiverChain:_dataB chainKey:_chainKeyB];
    
    XCTAssertEqualObjects([state receiverChainKey:_chainKeyA.key].key, _dataA);
    XCTAssertEqualObjects([state receiverChainKey:_chainKeyB.key].key, _dataB);
    
    [state setReceiverChainKey:_dataB chainKey:_chainKeyC];
    
    XCTAssertEqualObjects([state receiverChainKey:_chainKeyA.key].key, _dataA);
    XCTAssertEqualObjects([state receiverChainKey:_chainKeyB.key].key, _dataC);
}

-(void)testMessageKeys {
    SessionState* state = [[SessionState alloc]init];
    [state addReceiverChain:_dataA chainKey:_chainKeyA];
    [state addReceiverChain:_dataB chainKey:_chainKeyB];
    
    MessageKeys* messageKeys1 = [[MessageKeys alloc]initWithCipherKey:_dataA macKey:_dataB iv:_dataC index:0];
    MessageKeys* messageKeys2 = [[MessageKeys alloc]initWithCipherKey:_dataA macKey:_dataB iv:_dataC index:1];
    
    
    XCTAssertFalse([state removeMessageKeys:_dataA counter:0] != nil);
    XCTAssertFalse([state removeMessageKeys:_dataA counter:1] != nil);
    [state setMessageKeys:_dataA messageKeys:messageKeys1];
    XCTAssertFalse([state removeMessageKeys:_dataA counter:1] != nil);
    XCTAssertTrue([state removeMessageKeys:_dataA counter:0] != nil);
    [state setMessageKeys:_dataA messageKeys:messageKeys1];
    [state setMessageKeys:_dataA messageKeys:messageKeys2];
    
    XCTAssertTrue([state removeMessageKeys:_dataA counter:1] != nil);
    XCTAssertTrue([state removeMessageKeys:_dataA counter:0] != nil);
    
    [state setMessageKeys:_dataA messageKeys:messageKeys1];
    [state setMessageKeys:_dataA messageKeys:messageKeys2];
    [state removeMessageKeys:_dataA counter:0];
    XCTAssertFalse([state removeMessageKeys:_dataA counter:0] != nil);
    XCTAssertTrue([state removeMessageKeys:_dataA counter:1] != nil);
}

-(void)testPendingInitKey {
    SessionState* state = [[SessionState alloc]init];
    XCTAssertFalse([state pendingInitKey] != nil);
    [state setPendingInitKey:_idA signedInitKeyId:_stringIdC baseKey:_dataA];
    XCTAssertTrue([state pendingInitKey] != nil);
    XCTAssertEqualObjects([state pendingInitKey].baseKey, _dataA);
    [state clearPendingInitKey];
    XCTAssertFalse([state pendingInitKey] != nil);
}

@end

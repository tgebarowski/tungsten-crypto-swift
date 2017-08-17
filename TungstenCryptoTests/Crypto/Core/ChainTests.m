//
//  Copyright © 2017 Tungsten Labs UG. All rights reserved.
//
//  Licensed according to https://www.gnu.org/licenses/gpl-3.0.html
//

#import <XCTest/XCTest.h>
#import <TungstenCrypto/TungstenCrypto-Swift.h>
#import <TungstenCrypto/SodiumKeyAgreement.h>
#import "NSData+RandomGenerator.h"
@import TungstenCrypto;

@interface ChainTests: XCTestCase

@property int idA;
@property NSData* dataA;
@property NSData* dataB;
@property NSData* dataC;
@property KeyPair* keyPairA;

@property ChainKey* chainKeyA;
@property MessageKeys* keysA;
@property MessageKeys* keysB;
@end

@implementation ChainTests

-(void)setUp {
    [super setUp];
    CryptoConfigurationBuilder* builder = [[CryptoConfigurationBuilder alloc]init];
    [CryptoToolkit.sharedInstance setup:builder.build error:nil];
    
    _dataA = [NSData garbageDataWithLength:32];
    _dataB = [NSData garbageDataWithLength:32];
    _dataC = [NSData garbageDataWithLength:32];
    _keyPairA = [CryptoToolkit.sharedInstance.configuration.keyAgreement generateKeyPair];
    _chainKeyA = [[ChainKey alloc]initWithKey:_dataA index:_idA];
    
    _keysA = [[MessageKeys alloc]initWithCipherKey:_dataB macKey:_dataB iv:_dataB index:2];
    _keysB = [[MessageKeys alloc]initWithCipherKey:_dataC macKey:_dataC iv:_dataC index:2];
}


-(void)testReceivingChain {
    ReceivingChain* receiving = [[ReceivingChain alloc]initWithChainKey:_chainKeyA senderCoreKey:_keyPairA.publicKey];
    
    [receiving addMessageKeysWithMessageKeys:_keysA];
    [receiving addMessageKeysWithMessageKeys:_keysB];
    
    XCTAssertEqualObjects(_chainKeyA.key, receiving.chainKey.key);
    XCTAssertEqual(_chainKeyA.index, receiving.chainKey.index);
    XCTAssertEqualObjects(_keyPairA.publicKey, receiving.senderCoreKey);
    
    NSMutableData* data = [NSMutableData data];
    
    NSKeyedArchiver* archiver = [[NSKeyedArchiver alloc]initForWritingWithMutableData:data];
    [archiver encodeObject:receiving forKey: @"key"];
    [archiver finishEncoding];
    
    NSKeyedUnarchiver* unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
    ReceivingChain* unarchivedReceiving = [unarchiver decodeObjectForKey:@"key"];
    
    XCTAssertEqualObjects(_chainKeyA.key, receiving.chainKey.key);
    XCTAssertEqual(_chainKeyA.index, receiving.chainKey.index);
    XCTAssertEqualObjects(_keyPairA.publicKey, receiving.senderCoreKey);
    
    XCTAssertEqualObjects(_keysA.macKey, [unarchivedReceiving.messageKeysList objectAtIndex:0].macKey);
    XCTAssertEqualObjects(_keysB.macKey, [unarchivedReceiving.messageKeysList objectAtIndex:1].macKey);
}

-(void)testSendingChain {
    SendingChain* sending = [[SendingChain alloc]initWithChainKey:_chainKeyA senderCoreKeyPair:_keyPairA];
    XCTAssertEqualObjects(_chainKeyA.key, sending.chainKey.key);
    XCTAssertEqual(_chainKeyA.index, sending.chainKey.index);
    XCTAssertEqualObjects(_keyPairA.privateKey, sending.senderCoreKeyPair.privateKey);
    XCTAssertEqualObjects(_keyPairA.publicKey, sending.senderCoreKeyPair.publicKey);
 
    NSMutableData* data = [NSMutableData data];
    
    NSKeyedArchiver* archiver = [[NSKeyedArchiver alloc]initForWritingWithMutableData:data];
    [archiver encodeObject:sending forKey: @"key"];
    [archiver finishEncoding];
    
    NSKeyedUnarchiver* unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
    SendingChain* unarchivedSending = [unarchiver decodeObjectForKey:@"key"];
    
    XCTAssertEqualObjects(_chainKeyA.key, unarchivedSending.chainKey.key);
    XCTAssertEqual(_chainKeyA.index, unarchivedSending.chainKey.index);
    XCTAssertEqualObjects(_keyPairA.privateKey, unarchivedSending.senderCoreKeyPair.privateKey);
    XCTAssertEqualObjects(_keyPairA.publicKey, unarchivedSending.senderCoreKeyPair.publicKey);
}

@end

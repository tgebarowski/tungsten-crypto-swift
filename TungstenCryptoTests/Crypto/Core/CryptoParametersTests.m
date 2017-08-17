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

@interface CryptoParametersTests : XCTestCase

@property NSData* dataA;
@property NSData* dataB;
@property NSData* dataC;
@property NSData* dataD;

@property KeyPair* keyPairA;
@property KeyPair* keyPairB;
@property KeyPair* keyPairC;
@property KeyPair* keyPairD;

@end

@implementation CryptoParametersTests

-(void)setUp {
    CryptoConfigurationBuilder* builder = [[CryptoConfigurationBuilder alloc]init];
    [CryptoToolkit.sharedInstance setup:builder.build error:nil];
    
    [super setUp];
    self.dataA = [NSData garbageDataWithLength:32];
    self.dataB = [NSData garbageDataWithLength:32];
    self.dataC = [NSData garbageDataWithLength:32];
    self.dataD = [NSData garbageDataWithLength:32];
    self.keyPairA = [CryptoToolkit.sharedInstance.configuration.keyAgreement generateKeyPair];
    self.keyPairB = [CryptoToolkit.sharedInstance.configuration.keyAgreement generateKeyPair];
    self.keyPairC = [CryptoToolkit.sharedInstance.configuration.keyAgreement generateKeyPair];
    self.keyPairD = [CryptoToolkit.sharedInstance.configuration.keyAgreement generateKeyPair];
}

-(void)testAlice {
    AliceCryptoParameters* parameters = [[AliceCryptoParameters alloc]initWithIdentityKey:_keyPairA theirIdentityKey:_dataA ourBaseKey:_keyPairB theirSignedInitKey:_dataB theirOneTimeInitKey:_dataC theirCoreKey:_dataD];
    
    XCTAssertEqualObjects(_keyPairA.privateKey, parameters.ourIdentityKeyPair.privateKey);
    XCTAssertEqualObjects(_keyPairA.publicKey, parameters.ourIdentityKeyPair.publicKey);
    
    XCTAssertEqualObjects(_keyPairB.privateKey, parameters.ourBaseKey.privateKey);
    XCTAssertEqualObjects(_keyPairB.publicKey, parameters.ourBaseKey.publicKey);
    
    XCTAssertEqualObjects(_dataA, parameters.theirIdentityKey);
    XCTAssertEqualObjects(_dataB, parameters.theirSignedInitKey);
    XCTAssertEqualObjects(_dataC, parameters.theirOneTimeInitKey);
    XCTAssertEqualObjects(_dataD, parameters.theirCoreKey);
    
    id<CryptoParameters> protocolParameters = parameters;
    
    XCTAssertEqualObjects(_keyPairA.privateKey, protocolParameters.ourIdentityKeyPair.privateKey);
    XCTAssertEqualObjects(_keyPairA.publicKey, protocolParameters.ourIdentityKeyPair.publicKey);
    XCTAssertEqualObjects(_dataA, protocolParameters.theirIdentityKey);
}

-(void)testBob {
    BobCryptoParameters* parameters = [[BobCryptoParameters alloc]initWithIdentityKey:_keyPairA theirIdentityKey:_dataA ourSignedInitKey:_keyPairB ourCoreKey:_keyPairC ourOneTimeInitKey:_keyPairD theirBaseKey:_dataD];
    
    XCTAssertEqualObjects(_keyPairA.publicKey, parameters.ourIdentityKeyPair.publicKey);
    XCTAssertEqualObjects(_keyPairA.privateKey, parameters.ourIdentityKeyPair.privateKey);
    XCTAssertEqualObjects(_dataA, parameters.theirIdentityKey);
    XCTAssertEqualObjects(_keyPairB.privateKey, parameters.ourSignedInitKey.privateKey);
    XCTAssertEqualObjects(_keyPairB.publicKey, parameters.ourSignedInitKey.publicKey);
    
    XCTAssertEqualObjects(_keyPairC.publicKey, parameters.ourCoreKey.publicKey);
    XCTAssertEqualObjects(_keyPairC.privateKey, parameters.ourCoreKey.privateKey);
    XCTAssertEqualObjects(_keyPairD.publicKey, parameters.ourOneTimeInitKey.publicKey);
    XCTAssertEqualObjects(_keyPairD.privateKey, parameters.ourOneTimeInitKey.privateKey);
    XCTAssertEqualObjects(_dataD, parameters.theirBaseKey);
    
    id<CryptoParameters> protocolParameters = parameters;
    
    XCTAssertEqualObjects(_keyPairA.privateKey, protocolParameters.ourIdentityKeyPair.privateKey);
    XCTAssertEqualObjects(_keyPairA.publicKey, protocolParameters.ourIdentityKeyPair.publicKey);
    XCTAssertEqualObjects(_dataA, protocolParameters.theirIdentityKey);
}


@end

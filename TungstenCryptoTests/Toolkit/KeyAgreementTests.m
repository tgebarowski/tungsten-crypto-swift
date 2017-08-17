//
//  Copyright © 2017 Tungsten Labs UG. All rights reserved.
//
//  Licensed according to https://www.gnu.org/licenses/gpl-3.0.html
//

#import <XCTest/XCTest.h>
#import <TungstenCrypto/SodiumKeyAgreement.h>
#import <TungstenCrypto/TungstenCrypto-Swift.h>
#import "NSData+DescriptionStringParsing.h"
@import TungstenCrypto;
@interface KeyAgreementTests: XCTestCase

@property id<KeyAgreement> keyAgreement;

@property NSArray<KeyPair*>* predefinedKeyArray;
@property NSArray<NSData*>* predefinedSharedSecretsArray;
@property KeyPair* predefinedKey;
@property NSData* predefinedMessage;
@property NSArray<NSData*>* predefinedSignatureArray;

@end

@implementation KeyAgreementTests

-(void)setUp {
    [super setUp];
    
    self.keyAgreement = [[SodiumKeyAgreement alloc]init];
    self.predefinedKeyArray = @[
    [[KeyPair alloc]initWithPrivateKey: [NSData dataFromDescriptionString: @"<cad30c92 5c1501ed c34b9e46 b5cb7ea9 a6bf47db 442012e6 f37034c6 86f7ab4d 7bc143cc 1b26d4b3 205ca0cd 2b3d13d1 ad1cd46c 74063a89 03dc6bd0 5b3859c8>"]
                             publicKey: [NSData dataFromDescriptionString: @"<7bc143cc 1b26d4b3 205ca0cd 2b3d13d1 ad1cd46c 74063a89 03dc6bd0 5b3859c8>"]],
    [[KeyPair alloc]initWithPrivateKey: [NSData dataFromDescriptionString: @"<f47245ee d5d0cfdf 3c0051b3 e6800478 fc85ff13 2400a92c 1b353dd7 63ef1c8c 9423f09c 89352040 bb309fd4 20cdac24 6a4a4669 319309ed 3ed2b770 959bab15>"]
                             publicKey: [NSData dataFromDescriptionString: @"<9423f09c 89352040 bb309fd4 20cdac24 6a4a4669 319309ed 3ed2b770 959bab15>"]],
    [[KeyPair alloc]initWithPrivateKey: [NSData dataFromDescriptionString: @"<25069df7 b3da0ce6 9087cc4c eeacc026 bea3a6cd 3b87db45 6e5f5e8d 20cb2b82 88c70fe9 ff8ec190 77cfdeda 844e14cf 015a1dc5 373cc07c 2d073c10 cbdae7fb>"]
                             publicKey: [NSData dataFromDescriptionString: @"<88c70fe9 ff8ec190 77cfdeda 844e14cf 015a1dc5 373cc07c 2d073c10 cbdae7fb>"]],
    [[KeyPair alloc]initWithPrivateKey: [NSData dataFromDescriptionString: @"<c1a36a72 9ed5f0e2 3baa97c5 6e30d6c2 1f5de118 c5cb49a4 d9824cc4 68546396 ad4df250 eab05b9e ed09ac99 77788671 5bbff15d 5e0c3c2d cbf418b7 ce28c7f0>"]
                             publicKey: [NSData dataFromDescriptionString: @"<ad4df250 eab05b9e ed09ac99 77788671 5bbff15d 5e0c3c2d cbf418b7 ce28c7f0>"]],
    [[KeyPair alloc]initWithPrivateKey: [NSData dataFromDescriptionString: @"<c56bce7b 4418ac31 4c67a44d b89d64c5 bf33c66c 717f8a1a 3bca5c38 10002914 466de342 680c3f1a e40571fb 500c9b04 f3f91dc0 4b8b07d3 f3933034 75d7e87e>"]
                             publicKey: [NSData dataFromDescriptionString: @"<466de342 680c3f1a e40571fb 500c9b04 f3f91dc0 4b8b07d3 f3933034 75d7e87e>"]],
    [[KeyPair alloc]initWithPrivateKey: [NSData dataFromDescriptionString: @"<9f91922e 5006805c 10f1b4da 7cf08be0 a697787e c7789098 78d33289 616bb67a e45194bb d9205b36 359c6dca fda752ae d6092780 071e9d7b ceb3d660 c8fddaa2>"]
                             publicKey: [NSData dataFromDescriptionString: @"<e45194bb d9205b36 359c6dca fda752ae d6092780 071e9d7b ceb3d660 c8fddaa2>"]],
    [[KeyPair alloc]initWithPrivateKey: [NSData dataFromDescriptionString: @"<a62b5e40 aa12c1d3 c5ea2ca9 8823fc6a d5b5e79a 9888e5a1 4ca08ca1 6f663779 ac1f4a5f 054a7628 769cbb1a faf78fad 5b99e044 cb261d7e d9162532 3da10d87>"]
                             publicKey: [NSData dataFromDescriptionString: @"<ac1f4a5f 054a7628 769cbb1a faf78fad 5b99e044 cb261d7e d9162532 3da10d87>"]],
    [[KeyPair alloc]initWithPrivateKey: [NSData dataFromDescriptionString: @"<e94fdb1b edbe9a1a 2f8e72dc 7d4af5a8 c89b8e18 b4ff9dda 3d647afa 2545694b 32a2e7f5 c9507590 d6bb04af 1a7eef10 19a5a2e9 ddb934ab c4d39174 b6419760>"]
                             publicKey: [NSData dataFromDescriptionString: @"<32a2e7f5 c9507590 d6bb04af 1a7eef10 19a5a2e9 ddb934ab c4d39174 b6419760>"]],
    [[KeyPair alloc]initWithPrivateKey: [NSData dataFromDescriptionString: @"<e92b6f66 1dbc176a 66867f39 38182956 f5cf4f59 3f567987 42cf67a2 49bacdff 4302f789 54ffb6a6 1d539634 fea6be53 6aef5f54 103d8d79 3ea4c861 c1ada946>"]
                             publicKey: [NSData dataFromDescriptionString: @"<4302f789 54ffb6a6 1d539634 fea6be53 6aef5f54 103d8d79 3ea4c861 c1ada946>"]],
    [[KeyPair alloc]initWithPrivateKey: [NSData dataFromDescriptionString: @"<57ce4113 c364ea0c 9b2302c4 b76bbcb6 98c0400f b4ce1317 e60efa00 345829ee 4c0ddd6d 06834a8a b898b531 c506b28c 6e52f9f2 fed89ca6 f76e33e7 e6030b76>"]
                             publicKey: [NSData dataFromDescriptionString: @"<4c0ddd6d 06834a8a b898b531 c506b28c 6e52f9f2 fed89ca6 f76e33e7 e6030b76>"]]
    ];
    self.predefinedKey = [[KeyPair alloc]initWithPrivateKey: [NSData dataFromDescriptionString: @"<0fe0937c 55f6c432 4698b1c3 46c4ed41 897a7b27 e5c581ae e2a212fd 076180d9 6f618c42 58ddaba4 c0dcd428 602ddca4 660eb9d4 d2037960 38aec242 0f6337cc>"]
                                                  publicKey: [NSData dataFromDescriptionString: @"<6f618c42 58ddaba4 c0dcd428 602ddca4 660eb9d4 d2037960 38aec242 0f6337cc>"]];
    
    self.predefinedSharedSecretsArray = @[
                                          [NSData dataFromDescriptionString:@"<58ecc0e1 af12d0c8 3638d5fe e1d549fc 0273e752 43ad93a2 160e4b37 723ee91f>"],
                                          [NSData dataFromDescriptionString:@"<fa8ebc24 b3483fb5 a9af2649 d1d15316 03040017 134c2566 7283c8d7 4107ed37>"],
                                          [NSData dataFromDescriptionString:@"<4e6310af f5186fef 9d9a1183 e68d0eca c51d5a31 cd6e21d8 c4bcbf87 500f9345>"],
                                          [NSData dataFromDescriptionString:@"<7998f335 d1395ff5 e0c3d60c 5eb3cc3c 9bee0335 8cc6b077 9ed6a8ac b36bbc76>"],
                                          [NSData dataFromDescriptionString:@"<afefc4dc 628d54f8 c6d31727 9c18a079 135c07fe 19adc81c 32225794 8e187e14>"],
                                          [NSData dataFromDescriptionString:@"<893ab80e 7d1f8e37 e96e22f9 f5ee0d5f a09c37ce 6acb43ca 57297d58 ffd8e328>"],
                                          [NSData dataFromDescriptionString:@"<8338d8e0 65683db6 7c266cf3 7141ea37 88bda23c 543c355e bd29b4a2 96c5c246>"],
                                          [NSData dataFromDescriptionString:@"<3a3d97b2 f3744342 eb48e53e 7df2c33e 981d2004 97702214 7507eac8 f7770f0f>"],
                                          [NSData dataFromDescriptionString:@"<02adc3a5 6e3ecb8d bdef5576 c75b472c be27994f c77daccf 6ed2f749 170f614b>"],
                                          [NSData dataFromDescriptionString:@"<35d8da18 9844363a b03aca4e 819d3347 d5c2f9d6 1ca19190 73c470e8 48ead75a>"]
                                          ];
    
    self.predefinedMessage = [NSData dataFromDescriptionString:@"<3a3d97b2 f3744342 eb48e53e 7df2c33e 981d2004 97702214 7507eac8 f7770f0f>"];
    
    self.predefinedSignatureArray = @[
                                      [NSData dataFromDescriptionString:@"<f97d2bd1 f738bfe3 ece18c95 8f917f9b f9825de9 2411d852 b4323c22 d7622342 16562d66 35e99638 a1ccc84f 85734a83 de1128cc f6867620 34702070 24853908>"],
                                      [NSData dataFromDescriptionString:@"<e37e2bbf acf2a48c a7e9f068 447b8b71 0941cdf8 57a91237 d5412a45 b1c10c88 6d026c99 0cf5ecce 3524ca2e 9ed935f7 419b56f4 d49a2268 c74a5557 f5652c09>"],
                                      [NSData dataFromDescriptionString:@"<b3c4918f 7a0f6c29 66b223f5 7327b883 2c301099 82186c2b 7a272ba4 9423dd90 994d767f 78e70c68 7470a3af db4ddec8 beb85a81 04eca851 ae88c073 0b0f2d0e>"],
                                      [NSData dataFromDescriptionString:@"<60fc1af6 eb2e8dda e5ffd1da c6bcc11f 5ededb05 658ffad2 2c1a265a 4f6a9e22 c106e192 14d62d47 7e429b8f 5cfe3959 e0b69f69 afa44289 9e486135 1f9a0f0c>"],
                                      [NSData dataFromDescriptionString:@"<bcf56131 43361d8d 8f2b11f8 4de58488 d4974e44 6a303afd 74a0d271 a7e095b1 819351f1 d914c03d 224b6695 77a1c3e9 f5510bc3 e36f929d 419b3b0a a3b86e04>"],
                                      [NSData dataFromDescriptionString:@"<93dbc31d 7e10354c 43956d22 ed933432 400db5e7 04a44ef3 77ac2685 7f997182 ecfc9b3d ab89fdd8 d487fe9c 1fb759a2 6f7cbf88 c8a426b1 2c4a89fa 1ba5fb0e>"],
                                      [NSData dataFromDescriptionString:@"<035a1617 eeb1124b 42aa8499 c1356735 19188e4a bd4c998e f8861fd1 25e8a972 7a54cc43 3e43d5d9 e30b924e 4afa0571 4d03639f bd7ddd6f 6962f014 ebeabb03>"],
                                      [NSData dataFromDescriptionString:@"<bbeb33ea 1dc7b02d 3c31fbfb f91978fa 6f1a0e08 288f5eb8 1768c5ce 252ffd17 17981daf 6ae469ff 84b10685 a84e1c75 9498b1d3 140dfece d7033a1c 19cc8b08>"],
                                      [NSData dataFromDescriptionString:@"<f8739e8b 9f3873c6 8fb5e1ab b1466770 76a5322f 922208ef 017d39d2 1c1bfc9a 77e41e7b 26c1c0ff 234885de 5539a7e5 6b9412bc b35b11ac 8b77a56e 9a01e904>"],
                                      [NSData dataFromDescriptionString:@"<1c12ca63 32e3db55 8f6231b1 8bacc00c 925f8411 7941da62 4fc7cb8d 8196757d a2666dc0 b3fb79b1 8d64492d af1ff11e 64c4955e ff178997 e9a55573 20d60604>"]
                                      ];
}

-(void)tearDown {
    [super tearDown];
}

-(void)testKeyPairGeneration {
    for(int i=0;i<10;i++) {
        KeyPair* keyPair = [self.keyAgreement generateKeyPair];
        XCTAssertNotNil(keyPair);
        XCTAssertNotNil(keyPair.publicKey);
        XCTAssertNotNil(keyPair.privateKey);
        
        XCTAssertEqual(keyPair.publicKey.length, 32);
        XCTAssertEqual(keyPair.privateKey.length, 64);
    }
}

-(void)testSharedSecretGeneration {
    
    for(int i=0; i<10000; i++) {
        KeyPair* keyPairA = [self.keyAgreement generateKeyPair];
        KeyPair* keyPairB = [self.keyAgreement generateKeyPair];
        KeyPair* keyPairC = [self.keyAgreement generateKeyPair];
        
        XCTAssertNotEqualObjects(keyPairA.publicKey, keyPairB.publicKey);
        XCTAssertNotEqualObjects(keyPairA.privateKey, keyPairB.privateKey);
        
        NSData* sharedSecretA = [self.keyAgreement sharedSecredFrom:keyPairA.publicKey keyPair:keyPairB];
        NSData* sharedSecretB = [self.keyAgreement sharedSecredFrom:keyPairB.publicKey keyPair:keyPairA];
        NSData* sharedSecretC = [self.keyAgreement sharedSecredFrom:keyPairA.publicKey keyPair:keyPairC];
        
        XCTAssertNotNil(sharedSecretA);
        XCTAssertNotNil(sharedSecretB);
        
        XCTAssertEqualObjects(sharedSecretA, sharedSecretB);
        XCTAssertNotEqualObjects(sharedSecretB, sharedSecretC);
        XCTAssertNotEqualObjects(sharedSecretA, sharedSecretC);
    }
}

-(void)testSignature {
    for(int i=0; i<10000; i++) {
        KeyPair* keyPairA = [self.keyAgreement generateKeyPair];
        NSData* singatureData = [self garbageDataWithLength:16];
        
        NSData* signature = [self.keyAgreement signWithData:singatureData keyPair:keyPairA];
        XCTAssertNotNil(signature);
        
        XCTAssertTrue([self.keyAgreement verifyWithSignature:signature publicKey:keyPairA.publicKey data:singatureData]);
    }
}

-(void)testVerifySignatureInvalidSignature {
    KeyPair* keyPairA = [self.keyAgreement generateKeyPair];
    NSData* singatureData = [self garbageDataWithLength:16];
    
    NSData* signature = [self.keyAgreement signWithData:singatureData keyPair:keyPairA];
    XCTAssertNotNil(signature);
    
    XCTAssertFalse([self.keyAgreement verifyWithSignature:signature publicKey:keyPairA.publicKey data:[self garbageDataWithLength:32]]);
}


-(void)testPredefinedAgreements {
    for(int i=0; i<self.predefinedKeyArray.count;i++) {
        NSData* sharedA = [self.keyAgreement sharedSecredFrom:self.predefinedKey.publicKey keyPair:self.predefinedKeyArray[i]];
        NSData* sharedB = [self.keyAgreement sharedSecredFrom:self.predefinedKeyArray[i].publicKey keyPair:self.predefinedKey];
        NSData* sharedC = [self.predefinedSharedSecretsArray objectAtIndex:i];
        XCTAssertEqualObjects(sharedB, sharedA);
        XCTAssertEqualObjects(sharedC, sharedA);
    }
}

-(void)testPredefinedSignatures {
    for(int i=0; i<self.predefinedKeyArray.count;i++) {
        NSData* signatureA = [self.keyAgreement signWithData:self.predefinedMessage keyPair:[self.predefinedKeyArray objectAtIndex:i]];
        NSData* signatureB = [self.predefinedSignatureArray objectAtIndex:i];
        XCTAssertEqualObjects(signatureA, signatureB);
        XCTAssertTrue([self.keyAgreement verifyWithSignature:signatureA publicKey:[self.predefinedKeyArray objectAtIndex:i].publicKey  data:self.predefinedMessage]);
    }
}

-(NSData*)garbageDataWithLength:(int) length {
    
    void * bytes = malloc(length);
    NSData * data = [NSData dataWithBytes:bytes length:length];
    free(bytes);
    
    return  data;
}

@end

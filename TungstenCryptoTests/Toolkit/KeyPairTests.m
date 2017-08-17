//
//  Copyright © 2017 Tungsten Labs UG. All rights reserved.
//
//  Licensed according to https://www.gnu.org/licenses/gpl-3.0.html
//

#import <XCTest/XCTest.h>
#import <TungstenCrypto/TungstenCrypto-Swift.h>

@interface KeyPairTests: XCTestCase
@property NSData* dataA;
@property NSData* dataB;
@end

@implementation KeyPairTests

-(void)setUp {
    [super setUp];
    
    _dataA = [[NSData alloc]initWithBase64EncodedString: @"dGVzdA==" options:0];
    _dataB = [[NSData alloc]initWithBase64EncodedString: @"dGVzdHRlc3Q=" options:0];
}

-(void)tearDown {
    [super tearDown];
}

-(void)testKeyPairCreation {
    KeyPair* keypair = [[KeyPair alloc] initWithPrivateKey:self.dataA publicKey:self.dataB];
    
    XCTAssertEqualObjects(self.dataA, [keypair privateKey]);
    XCTAssertEqualObjects(self.dataB, [keypair publicKey]);
}

-(void)testKeyPairEncoding {
    KeyPair* keypair = [[KeyPair alloc] initWithPrivateKey:self.dataA publicKey:self.dataB];
    
    NSMutableData* data = [NSMutableData data];
    
    NSKeyedArchiver* archiver = [[NSKeyedArchiver alloc]initForWritingWithMutableData:data];
    [archiver encodeObject:keypair forKey: @"key"];
    [archiver finishEncoding];
    
    NSKeyedUnarchiver* unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
    KeyPair* unarchivedKeyPair = [unarchiver decodeObjectForKey:@"key"];
    
    XCTAssertNotNil(unarchivedKeyPair);
   
    XCTAssertEqualObjects(unarchivedKeyPair.privateKey, keypair.privateKey);
    XCTAssertEqualObjects(unarchivedKeyPair.publicKey, keypair.publicKey);
}

@end

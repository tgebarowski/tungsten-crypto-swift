//
//  Copyright © 2017 Tungsten Labs UG. All rights reserved.
//
//  Licensed according to https://www.gnu.org/licenses/gpl-3.0.html
//

#import <XCTest/XCTest.h>
#import <TungstenCrypto/TungstenCrypto-Swift.h>
#import <TungstenCrypto/AESCBCSymmetricCipher.h>

@import TungstenCrypto;
@interface SymmetricCipherTests : XCTestCase

@property id<SymmetricCipher> symmetricCipher;

@property NSData* plainText;
@property NSData* key;
@property NSData* iv;

@end

@implementation SymmetricCipherTests

-(void)setUp {
    [super setUp];
    
    self.symmetricCipher = [[AESCBCSymmetricCipher alloc]init];
    self.plainText = [self garbageDataWithLength:2813];
    self.key = [self garbageDataWithLength:32];
    self.iv = [self garbageDataWithLength:16];
}

-(void)tearDown {
    [super tearDown];
}

-(void)testEncryptionDecryption {
    NSError* error = nil;
    NSData* cipherText = [self.symmetricCipher encryptWithData:self.plainText key:self.key iv:self.iv error:&error];
    XCTAssertNil(error);
    NSData* decipheredText = [self.symmetricCipher decryptWithData:cipherText key:self.key iv:self.iv error:&error];
    XCTAssertNil(error);
    XCTAssertEqualObjects(self.plainText, decipheredText);
}

-(void)testEncryptionDecrypionNoIV {
    NSError* error = nil;
    NSData* cipherText = [self.symmetricCipher encryptWithData:self.plainText key:self.key iv:nil error:&error];
    XCTAssertNil(error);
    NSData* decipheredText = [self.symmetricCipher decryptWithData:cipherText key:self.key iv:nil error:&error];
    XCTAssertNil(error);
    XCTAssertEqualObjects(self.plainText, decipheredText);
}

-(NSData*)garbageDataWithLength:(int) length {
    
    void * bytes = malloc(length);
    NSData * data = [NSData dataWithBytes:bytes length:length];
    free(bytes);
    
    return  data;
}

@end

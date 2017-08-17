//
//  Copyright © 2017 Tungsten Labs UG. All rights reserved.
//
//  Licensed according to https://www.gnu.org/licenses/gpl-3.0.html
//

#import <XCTest/XCTest.h>
#import <TungstenCrypto/TungstenCrypto-Swift.h>
#import <TungstenCrypto/AESCBCSymmetricCipher.h>
#import "NSData+crypto_AES.h"

@interface AESTests : XCTestCase

@property NSObject<SymmetricCipher>* symmetricCipher;

@end

@implementation AESTests

- (void)setUp {
    [super setUp];
    self.symmetricCipher = [[AESCBCSymmetricCipher alloc]init];
}

- (void)tearDown {
    
    [super tearDown];
}

-(void)testIVGeneration {
    
    NSData* aes = [self.symmetricCipher generateIV];
    NSData* aes2 = [self.symmetricCipher generateIV];
    NSData* crypto_aes = [NSData crypto_AES256GenerateInitializationVector];
    
    XCTAssertNotNil(aes);
    XCTAssertNotNil(aes2);
    XCTAssertEqual([aes length], [crypto_aes length]);
    XCTAssertEqual([aes2 length], [crypto_aes length]);
    XCTAssertNotEqualObjects(aes, aes2);
}

-(void)testKeyGeneration {
    NSData* aes = [self.symmetricCipher generateKey];
    NSData* aes2 = [self.symmetricCipher generateKey];
    NSData* crypto_aes = [NSData crypto_AES256GenerateKey];
    
    XCTAssertNotNil(aes);
    XCTAssertNotNil(aes2);
    XCTAssertEqual([aes length], [crypto_aes length]);
    XCTAssertEqual([aes2 length], [crypto_aes length]);
    XCTAssertNotEqualObjects(aes, aes2);
}

-(void)testIVBase64Generation {
    NSString* aes = [[self.symmetricCipher generateIV] base64EncodedStringWithOptions:0];
    NSString* aes2 = [[self.symmetricCipher generateIV] base64EncodedStringWithOptions:0];
    NSString* crypto_aes = [NSData crypto_AES256GenerateBase64EncodedInitializationVector];
    
    XCTAssertNotNil(aes);
    XCTAssertNotNil(aes2);
    XCTAssertEqual([aes length], [crypto_aes length]);
    XCTAssertEqual([aes2 length], [crypto_aes length]);
    XCTAssertNotEqualObjects(aes, aes2);
}

-(void)testKeyBase64Generation {
    NSString* aes = [[self.symmetricCipher generateKey] base64EncodedStringWithOptions:0];
    NSString* aes2 = [[self.symmetricCipher generateKey] base64EncodedStringWithOptions:0];
    NSString* crypto_aes = [NSData crypto_AES256GenerateBase64EncodedKey];
    
    XCTAssertNotNil(aes);
    XCTAssertNotNil(aes2);
    XCTAssertEqual([aes length], [crypto_aes length]);
    XCTAssertEqual([aes2 length], [crypto_aes length]);
    XCTAssertNotEqualObjects(aes, aes2);
}

-(void)testEncryptionWithIV {
    NSData* key = [self.symmetricCipher generateKey];
    NSData* iv = [self.symmetricCipher generateIV];
    
    NSData* crypto_key = [NSData crypto_AES256GenerateKey];
    NSData* crypto_iv = [NSData crypto_AES256GenerateInitializationVector];
    
    NSData* payload = [@"Initial payload" dataUsingEncoding: NSUTF8StringEncoding];
    
    NSData* encryptedPayload = [self.symmetricCipher encryptWithData:payload key:crypto_key iv:crypto_iv error:nil];
    
    NSData* crypto_encryptedPayload = [payload crypto_AES256EncryptedDataWithKey: key iv: iv];
    
    NSData* decryptedPayload = [encryptedPayload crypto_AES256DecryptedDataWithKey: crypto_key iv:crypto_iv];
    NSData* crypto_decryptedPayload = [self.symmetricCipher decryptWithData:crypto_encryptedPayload key:key iv:iv error:nil];
    
    XCTAssertEqualObjects(payload, decryptedPayload);
    XCTAssertEqualObjects(payload, crypto_decryptedPayload);
}

-(void)testEncryptionWithoutIV {
    NSData* key = [self.symmetricCipher generateKey];
    NSData* crypto_key = [NSData crypto_AES256GenerateKey];
    
    NSData* payload = [@"Initial payload" dataUsingEncoding: NSUTF8StringEncoding];
    
    NSData* encryptedPayload = [self.symmetricCipher encryptWithData:payload key:crypto_key iv:nil error:nil];
    NSData* crypto_encryptedPayload = [payload crypto_AES256EncryptedDataWithKey: key];
    
    NSData* decryptedPayload = [encryptedPayload crypto_AES256DecryptedDataWithKey: crypto_key];
    NSData* crypto_decryptedPayload = [self.symmetricCipher decryptWithData:crypto_encryptedPayload key:key iv:nil error:nil];
    
    XCTAssertEqualObjects(payload, decryptedPayload);
    XCTAssertEqualObjects(payload, crypto_decryptedPayload);
}

@end

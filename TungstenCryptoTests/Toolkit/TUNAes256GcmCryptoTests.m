//
//  Copyright © 2017 Tungsten Labs UG. All rights reserved.
//
//  Licensed according to https://www.gnu.org/licenses/gpl-3.0.html
//

#import <XCTest/XCTest.h>
#import "TUNAes256GcmCipher.h"
#import <TungstenCrypto/TungstenCrypto-Swift.h>

@interface TUNAes256GcmCryptoTests : XCTestCase

@property (nonatomic, strong) TUNAes256GcmCipher *sut;
@end

@implementation TUNAes256GcmCryptoTests

- (void)setUp {
    [super setUp];
    
    self.sut = [[TUNAes256GcmCipher alloc] init];
}

- (void)tearDown  {
    self.sut = nil;
    
    [super tearDown];
}

- (void)testInitializationVectorGeneration {
    NSData *iv1 = [self.sut generateIV];
    NSData *iv2 = [self.sut generateIV];
    
    BOOL initializationVectorsNotEqual = ![iv1 isEqualToData:iv2];
    XCTAssertTrue(initializationVectorsNotEqual);
}

- (void)testGeneratedInitializationVectorLength {
    NSData *iv = [self.sut generateIV];

    XCTAssertEqual(iv.length, 16);
}

- (void)testKeyGeneration {
    NSData *key1 = [self.sut generateKey];
    NSData *key2 = [self.sut generateKey];
    
    BOOL keysNotEqual = ![key1 isEqualToData:key2];
    XCTAssertTrue(keysNotEqual);
}

- (void)testGeneratedKeyLength {
    NSData *key = [self.sut generateKey];

    XCTAssertEqual(key.length, 32);
}

- (void)testEncryption {
    TUNAes256GcmCipher *crypto = self.sut;
    NSData *inputPlaintext = [@"test plaintext test" dataUsingEncoding:NSUTF8StringEncoding];
    NSData *key = [self.sut generateKey];
    NSData *iv = [self.sut generateIV];
    
    NSError *localError;
    NSData *cipherText = [crypto encryptWithData:inputPlaintext key:key iv:iv error:&localError];
    
    XCTAssertNil(localError);
    XCTAssertGreaterThan(cipherText.length, 0);
    
    BOOL plaintextDataNotEqualToDecryptedData = ![inputPlaintext isEqualToData:cipherText];
    XCTAssertTrue(plaintextDataNotEqualToDecryptedData);
}

- (void)testEncryptionAndDecryption {
    TUNAes256GcmCipher *crypto = self.sut;
    
    NSData *inputPlaintext = [@"test plaintext" dataUsingEncoding:NSUTF8StringEncoding];
    NSData *key = [self.sut generateKey];
    NSData *iv = [self.sut generateIV];
    
    NSError *localError;
    NSData *cipherText = [crypto encryptWithData:inputPlaintext
                                             key:key iv:iv
                                           error:&localError];
    ;
    XCTAssertNil(localError);
    XCTAssertGreaterThan(cipherText.length, 0);
    
    NSData *plainText =
    [crypto decryptWithData:cipherText key:key iv:iv error:&localError];
    
    XCTAssertNil(localError);
    XCTAssertGreaterThan(plainText.length, 0);
    
    BOOL plaintextDataEqualToDecryptedData = [inputPlaintext isEqualToData:plainText];
    XCTAssertTrue(plaintextDataEqualToDecryptedData);
}

@end

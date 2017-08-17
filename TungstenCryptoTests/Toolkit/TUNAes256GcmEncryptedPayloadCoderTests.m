//
//  Copyright © 2017 Tungsten Labs UG. All rights reserved.
//
//  Licensed according to https://www.gnu.org/licenses/gpl-3.0.html
//

#import <XCTest/XCTest.h>
#import "TUNAes256GcmAuthenticatedCiphertextComposer.h"

@interface TUNAes256GcmEncryptedPayloadCoderTests : XCTestCase

@property (nonatomic, strong) TUNAes256GcmAuthenticatedCiphertextComposer *sut;

@end

@implementation TUNAes256GcmEncryptedPayloadCoderTests

- (void)setUp {
    [super setUp];

    self.sut = [[TUNAes256GcmAuthenticatedCiphertextComposer alloc] initWithAuthenticationTagSize:16];
}

- (void)tearDown  {
    self.sut = nil;

    [super tearDown];
}

- (void)testPayloadEncoding {
    unsigned char contentChars[] = {
            0x4d, 0x23, 0xc3, 0xce,
            0xc3, 0x34, 0xb4, 0x9b,
            0xdb, 0x37, 0x0c, 0x43,
            0x7f, 0xec, 0x78, 0xde,
            0x7f, 0xec, 0x78, 0xde
    };

    unsigned char authenticationTagBytes[] = {
            0x4d, 0x23, 0xc3, 0xce,
            0xc3, 0x34, 0xb4, 0x9b,
            0xdb, 0x37, 0x0c, 0x43,
            0x7f, 0xec, 0x78, 0xde
    }; // 16 bytes

    NSData *content = [NSData dataWithBytes:contentChars
                                     length:sizeof(contentChars)];
    NSData *authenticationTag = [NSData dataWithBytes:authenticationTagBytes
                                               length:sizeof(authenticationTagBytes)];

    NSData *encodedPayload = [self.sut composeAuthenticatedCiphertextWithCiphertext:content
                                                                  authenticationTag:authenticationTag];

    XCTAssertEqual(encodedPayload.length, content.length + authenticationTag.length);
}

- (void)testPayloadEncodingAndDecoding {
    unsigned char contentChars[] = {
            0x4d, 0x23, 0xc3, 0xce,
            0xc3, 0x34, 0xb4, 0x9b,
            0xdb, 0x37, 0x0c, 0x43,
            0x7f, 0xec, 0x78, 0xde,
            0x7f, 0xec, 0x78, 0xde
    };

    unsigned char authenticationTagBytes[] = {
            0x4d, 0x23, 0xc3, 0xce,
            0xc3, 0x34, 0xb4, 0x9b,
            0xdb, 0x37, 0x0c, 0x43,
            0x7f, 0xec, 0x78, 0xde
    }; // 16 bytes

    NSData *content = [NSData dataWithBytes:contentChars
                                     length:sizeof(contentChars)];
    NSData *authenticationTag = [NSData dataWithBytes:authenticationTagBytes
                                               length:sizeof(authenticationTagBytes)];

    NSData *encodedPayload = [self.sut composeAuthenticatedCiphertextWithCiphertext:content
                                                                  authenticationTag:authenticationTag];

    NSDictionary *decodedPayload = [self.sut decomposeAuthenticatedCiphertext:encodedPayload];
    NSData *decodedContent = decodedPayload[TUNAes256GcmAuthenticatedCiphertextComposerCiphertextKey];
    NSData *decodedTag = decodedPayload[TUNAes256GcmAuthenticatedCiphertextComposerAuthTagKey];

    BOOL contentsEqual = [content isEqualToData:decodedContent];
    BOOL tagsEqual = [authenticationTag isEqualToData:decodedTag];

    XCTAssertTrue(contentsEqual);
    XCTAssertTrue(tagsEqual);
}

@end

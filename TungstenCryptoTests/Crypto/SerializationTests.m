//
//  Copyright © 2017 Tungsten Labs UG. All rights reserved.
//
//  Licensed according to https://www.gnu.org/licenses/gpl-3.0.html
//

#import <XCTest/XCTest.h>
#import <CommonCrypto/CommonHMAC.h>
#import <TungstenCrypto/TungstenCrypto-Swift.h>
#import <TungstenCrypto/HMACKDFKeyDerivation.h>
#import "NSData+RandomGenerator.h"

#define MAC_LENGTH 8

@interface SerializationTests: XCTestCase

@end


@implementation SerializationTests

+ (NSData*)oldMacWithVersion:(int)version
              identityKey:(NSData*)senderIdentityKey
      receiverIdentityKey:(NSData*)receiverIdentityKey
                   macKey:(NSData*)macKey
               serialized:(NSData*)serialized {
    
    uint8_t ourHmac[CC_SHA256_DIGEST_LENGTH] = {0};
    CCHmacContext context;
    CCHmacInit  (&context, kCCHmacAlgSHA256, [macKey bytes], [macKey length]);
    CCHmacUpdate(&context, [senderIdentityKey bytes], [senderIdentityKey length]);
    CCHmacUpdate(&context, [receiverIdentityKey bytes], [receiverIdentityKey length]);
    CCHmacUpdate(&context, [serialized bytes], [serialized length]);
    CCHmacFinal (&context, &ourHmac);
    
    return [NSData dataWithBytes:ourHmac length:MAC_LENGTH];
}


-(void)testMac {
    
    HMACKDFKeyDerivation* keyDeriviation = [[HMACKDFKeyDerivation alloc]init];
    
    int version = 4;
    NSData* identityKey = [NSData garbageDataWithLength:32];
    NSData* receiverIdentityKey = [NSData garbageDataWithLength:32];
    NSData* macKey = [NSData garbageDataWithLength:32];
    NSData* serialized = [NSData garbageDataWithLength:32];
    
    NSData* oldMac = [SerializationTests oldMacWithVersion:version identityKey:identityKey receiverIdentityKey:receiverIdentityKey macKey:macKey serialized:serialized];
    
    NSData* newMac = [keyDeriviation hmacWithSenderIdentityKey:identityKey receiverIdentityKey:receiverIdentityKey macKey:macKey serialized:serialized];
    newMac = [newMac subdataWithRange:NSMakeRange(0, 8)];
    
    
    XCTAssertEqualObjects(oldMac, newMac);
}


@end

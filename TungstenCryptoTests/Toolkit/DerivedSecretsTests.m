//
//  Copyright © 2017 Tungsten Labs UG. All rights reserved.
//
//  Licensed according to https://www.gnu.org/licenses/gpl-3.0.html
//

#import <XCTest/XCTest.h>
#import "NSData+RandomGenerator.h"
#import "HMACKDFKeyDerivation.h"
#import "NSData+RandomGenerator.h"
@interface DerivedSecretsTests : XCTestCase



@end

@interface HMACKDFKeyDerivation(Internal)

- (NSData *)deriveKey:(NSData *)seed info:(NSData *)info salt:(NSData *)salt outputSize:(int)outputSize error:(NSError**)error;

@end


@implementation DerivedSecretsTests

-(void)testDerivationDifferentOutputSize {
    NSData* seed = [NSData garbageDataWithLength:32];
    NSData* info = [NSData garbageDataWithLength:17];
    
    
    HMACKDFKeyDerivation* deriviation = [[HMACKDFKeyDerivation alloc]init];
    NSData* derivedValue96 = [deriviation deriveKey:seed info:info salt:nil outputSize:96 error: nil];
    NSData* derivedValue64 = [deriviation deriveKey:seed info:info salt:nil outputSize:64 error: nil];
    
    NSData* derivedValue96SubData = [derivedValue96 subdataWithRange:NSMakeRange(0, 64)];
    
    XCTAssertEqualObjects(derivedValue64, derivedValue96SubData);
}

@end

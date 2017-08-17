//
//  Copyright © 2017 Tungsten Labs UG. All rights reserved.
//
//  Licensed according to https://www.gnu.org/licenses/gpl-3.0.html
//

#import <XCTest/XCTest.h>
#import <TungstenCrypto/TungstenCrypto-Swift.h>

@interface KeyVersionByteTests: XCTestCase

@property NSData* data32Bits;
@property NSData* data55Bits;

@end

@implementation KeyVersionByteTests

-(void)setUp {
    [super setUp];
    
    _data32Bits = [self garbageDataWithLength:32];
    _data55Bits = [self garbageDataWithLength:55];
}

-(void)testAddingRemovingVersionByte {
    NSData* newData = [self.data32Bits prependKeyType];
    XCTAssertEqual(newData.length, 33);
    UInt8 firstByte = ((UInt8*)newData.bytes)[0];
    XCTAssertEqual(firstByte, 0x05);
    
    NSError* error;
    NSData* anotherData = [newData removeKeyTypeAndReturnError:&error];
    XCTAssertNil(error);
    XCTAssertEqual(anotherData.length, 32);
    XCTAssertEqualObjects(anotherData, _data32Bits);
}

-(void)testInvalidInputData {
    NSData* newData = [self.data55Bits prependKeyType];
    XCTAssertEqual(newData, self.data55Bits);
    
    NSError* error;
    newData = [self.data55Bits removeKeyTypeAndReturnError:&error];
    XCTAssertNil(error);
    XCTAssertEqual(newData, self.data55Bits);
}

-(void)testErrorWhenWrongVersionByte {
    UInt8 firstByte = 0x34;
    NSMutableData* data = [NSMutableData dataWithBytes:&firstByte length:1];
    [data appendBytes:self.data32Bits.bytes length:self.data32Bits.length];
    
    NSError* error;
    NSData* newData = [data removeKeyTypeAndReturnError:&error];
    XCTAssertNil(newData);
    XCTAssertNotNil(error);
}

-(void)tearDown {
    [super tearDown];
}

-(NSData*)garbageDataWithLength:(int) length {
    
    void * bytes = malloc(length);
    NSData * data = [NSData dataWithBytes:bytes length:length];
    free(bytes);
    
    return  data;
}

@end

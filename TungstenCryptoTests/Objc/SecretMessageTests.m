//
//  Copyright © 2017 Tungsten Labs UG. All rights reserved.
//
//  Licensed according to https://www.gnu.org/licenses/gpl-3.0.html
//

#import <XCTest/XCTest.h>
#import <TungstenCrypto/TungstenCrypto-Swift.h>
@import TungstenCrypto;

@interface SecretMessageTests : XCTestCase
@property(nonatomic, strong) SecretMessage *secretMessage;

@property(nonatomic, assign) int version;
@property(nonatomic, strong) NSData *macKey;
@property(nonatomic, assign) int counter;
@property(nonatomic, assign) int previousCounter;
@property(nonatomic, strong) NSData *cipherText;
@property(nonatomic, strong) NSData *senderIdentityKey;
@property(nonatomic, strong) NSData *receiverIdentityKey;
@property(nonatomic, strong) NSData *senderCoreKey;
@property(nonatomic, strong) NSData *serializedMessage;

@property(nonatomic, strong) NSData *macResult;

@end

@implementation SecretMessageTests

- (void)setUp {
    [super setUp];
    CryptoConfigurationBuilder* builder = [[CryptoConfigurationBuilder alloc]init];
    [CryptoToolkit.sharedInstance setup:[builder build] error:nil];
    
    self.version = 3;
    self.macKey = [self dataFromDescriptionString:@"<df65a1b5 bd038b6d ec0e96c2 e36d42cb 1c719481 df45709e bf5c3818 8d27fca2>"];
    self.senderCoreKey = [self dataFromDescriptionString:@"0595345f b27579eb 740a8644 4a79d4bb c5c04342 a24b65d2 29f7f544 37ab5f57 0a"];
    self.counter = 0;
    self.previousCounter = 0;
    self.cipherText = [self dataFromDescriptionString:@"<94620764 42fe5fbc a2735a6c a1480079 088fe59e 72c3acbc 9e82723f 1ce673d9 f779418e 8b01b33f 08e0dfb1 cb4ae9dc>"];
    self.senderIdentityKey = [self dataFromDescriptionString:@"<056c0494 f545ae70 c723c33e 5fbc65b4 faef9f18 75b526a0 d0dfb1c7 a2e8a342 19>"];
    self.receiverIdentityKey = [self dataFromDescriptionString:@"<055ae582 a9034f96 8726a52e 9095f0f2 f4dcab1f f7b5b513 93650fd4 8d87db12 68>"];

    
    
    self.serializedMessage = [self dataFromDescriptionString:@"<330a2105 95345fb2 7579eb74 0a86444a 79d4bbc5 c04342a2 4b65d229 f7f54437 ab5f570a 10001800 22309462 076442fe 5fbca273 5a6ca148 0079088f e59e72c3 acbc9e82 723f1ce6 73d9f779 418e8b01 b33f08e0 dfb1cb4a e9dc73d7 196411bb a21a761f 35ea5ce7 acc5>"];
    
    self.macResult = [self dataFromDescriptionString:@"<73d71964 11bba21a 761f35ea 5ce7acc5>"];

}

- (void)tearDown {
    [super tearDown];
}

- (void)testWhisperMessageConstructorWithReferenceArguments {
    
    self.secretMessage = [[SecretMessage alloc] initWithVersion:self.version
                                                         macKey:self.macKey
                                                  senderCoreKey:self.senderCoreKey
                                                        counter:self.counter
                                                previousCounter:self.previousCounter
                                                     cipherText:self.cipherText
                                              senderIdentityKey:self.senderIdentityKey
                                            receiverIdentityKey:self.receiverIdentityKey];
    
    
    XCTAssertNotNil(self.secretMessage, @"It should create whisper message");
    
    XCTAssertNotNil(self.secretMessage.serialized, @"It should create serialized message");
    
    NSUInteger macSize = 16;
    NSUInteger macLocation = self.secretMessage.serialized.length - macSize;
    NSData *mac = [self.secretMessage.serialized subdataWithRange:NSMakeRange(macLocation, macSize)];
    
    XCTAssertNotNil(mac, @"It should be able to extract mac data");
    
    XCTAssertTrue([mac isEqualToData:self.macResult], @"It should calculate correct mac with reference data");
}

- (void)testProtoBuffsMessageSerialization {
    self.secretMessage = [[SecretMessage alloc] initWithVersion:self.version
                                                         macKey:self.macKey
                                                  senderCoreKey:self.senderCoreKey
                                                        counter:self.counter
                                                previousCounter:self.previousCounter
                                                     cipherText:self.cipherText
                                              senderIdentityKey:self.senderIdentityKey
                                            receiverIdentityKey:self.receiverIdentityKey];

    ProtobuffsMessageSerialization *serialization = [ProtobuffsMessageSerialization new];

    NSData *message = (NSData *) [serialization encodeMessageWithMessage:self.secretMessage];
    
    XCTAssertNotNil(message, @"It should be able to serialize message data");
    
    NSUInteger macSize = 16;
    NSRange rangeWithoutVersionByteAndMac = NSMakeRange(1, [self.secretMessage.serialized length] - 1 - macSize);
    NSData *dataWithoutVersionByteAndMac = [self.secretMessage.serialized subdataWithRange:rangeWithoutVersionByteAndMac];

    XCTAssertTrue([message isEqualToData:dataWithoutVersionByteAndMac], @"It should serialize message");
}

- (void)testProtoBuffsMessageDeserialization {
    ProtobuffsMessageSerialization *serialization = [ProtobuffsMessageSerialization new];
    NSError *error = nil;
    
    NSUInteger macSize = 16;
    NSRange rangeWithoutVersionByteAndMac = NSMakeRange(1, [self.serializedMessage length] - 1 - macSize);
    NSData *dataWithoutVersionByteAndMac = [self.serializedMessage subdataWithRange:rangeWithoutVersionByteAndMac];
    
    SecretMessageContainer *container = [serialization decodeMessageWithData:dataWithoutVersionByteAndMac error:&error];

    XCTAssertNotNil(container, @"It should be able to deserialize message data");
    XCTAssertNil(error, @"It should not return error");

    XCTAssertTrue([container.coreKey isEqualToData:self.senderCoreKey]);
    XCTAssertTrue([container.cipherText  isEqualToData:self.cipherText]);
    XCTAssertEqual([container.counter intValue], self.counter);
    XCTAssertEqual([container.previousCounter intValue], self.previousCounter);
}

- (void)testDataFromHexString {
    NSString *fixtureString = @"Foo Bar 123";
    NSData *originalData = [fixtureString dataUsingEncoding:NSUTF8StringEncoding];
    NSString *hexStringData = [NSString stringWithFormat:@"%@", originalData];
    
    NSData *convertedData = [self dataFromDescriptionString:hexStringData];
    
    XCTAssertTrue([originalData isEqualToData:convertedData], @"Data after conversion from description string should equal");
}


- (NSData *)dataFromDescriptionString:(NSString *)string {
    string = [string lowercaseString];
    NSMutableData *data= [NSMutableData new];
    unsigned char whole_byte;
    char byte_chars[3] = {'\0','\0','\0'};
    int i = 0;
    int length = (int)string.length;
    while (i < length-1) {
        char c = [string characterAtIndex:i++];
        if (c < '0' || (c > '9' && c < 'a') || c > 'f')
            continue;
        byte_chars[0] = c;
        byte_chars[1] = [string characterAtIndex:i++];
        whole_byte = strtol(byte_chars, NULL, 16);
        [data appendBytes:&whole_byte length:1];
    }
    return data;
}

@end

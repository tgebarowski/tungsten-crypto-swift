//
//  Copyright © 2017 Tungsten Labs UG. All rights reserved.
//
//  Licensed according to https://www.gnu.org/licenses/gpl-3.0.html
//

#import <XCTest/XCTest.h>
#import <TungstenCrypto/TungstenCrypto-Swift.h>

@interface InitKeySecretMessageTest : XCTestCase

@property(nonatomic, strong) NSData *initialKeyMessageData;
@property(nonatomic, strong) InitKeySecretMessage *initialKeySecretMessage;

@property(nonatomic, strong) NSData *serialized;
@property(nonatomic, assign) int registrationId;
@property(nonatomic, assign) int initKeyId;
@property(nonatomic, assign) int signedInitKeyId;
@property(nonatomic, strong) NSData *baseKey;
@property(nonatomic, strong) NSData *identityKey;

@property(nonatomic, assign) int version;
@property(nonatomic, strong) NSData *macKey;
@property(nonatomic, strong) NSData *senderCoreKey;
@property(nonatomic, assign) int counter;
@property(nonatomic, assign) int previousCounter;
@property(nonatomic, strong) NSData *cipherText;
@property(nonatomic, strong) NSData *senderIdentityKey;
@property(nonatomic, strong) NSData *serializedMessage;

@end

@implementation InitKeySecretMessageTest

- (void)setUp {
    [super setUp];

    self.initialKeyMessageData = [self dataFromDescriptionString:@""];

    // pre-key message
    self.serialized = [self dataFromDescriptionString:@""];
    self.registrationId = 0;
    self.initKeyId = 0;
    self.signedInitKeyId = 0;
    self.baseKey = [self dataFromDescriptionString:@""];
    self.identityKey = [self dataFromDescriptionString:@""];

    // inner whisper message
    self.version = 3;
    self.senderCoreKey = [self dataFromDescriptionString:@""];
    self.counter = 0;
    self.previousCounter = 0;
    self.cipherText = [self dataFromDescriptionString:@""];
    self.senderIdentityKey = [self dataFromDescriptionString:@"<"];
}

- (void)testInitKeySecretMessageDeserialization {
    NSError *error = nil;
    self.initialKeySecretMessage = [[InitKeySecretMessage alloc] initWithData:self.initialKeyMessageData
                                                                     error:&error];

    XCTAssertNil(error);

    // pre-key message
    XCTAssertTrue([self.initialKeySecretMessage.serialized isEqualToData:self.serialized]);
    XCTAssertEqual(self.initialKeySecretMessage.registrationId, self.registrationId);

    XCTAssertEqual(self.initialKeySecretMessage.initKeyID, self.initKeyId);
    XCTAssertEqual(self.initialKeySecretMessage.signedInitKeyId, self.signedInitKeyId);

    XCTAssertTrue([self.initialKeySecretMessage.baseKey isEqualToData:self.baseKey]);
    XCTAssertTrue([self.initialKeySecretMessage.identityKey isEqualToData:self.identityKey]);

    SecretMessage *message = self.initialKeySecretMessage.message;
    XCTAssertNotNil(message);
    XCTAssertEqual(message.version, self.version);
    XCTAssertEqual(message.previousCounter, self.previousCounter);
    XCTAssertEqual(message.counter, self.counter);
    XCTAssertTrue([message.senderCoreKey isEqualToData:self.senderIdentityKey]);
    XCTAssertTrue([message.cipherText isEqualToData:self.cipherText]);
    XCTAssertTrue([message.serialized isEqualToData:self.serializedMessage]);
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

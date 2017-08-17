//
//  Copyright © 2017 Tungsten Labs UG. All rights reserved.
//
//  Licensed according to https://www.gnu.org/licenses/gpl-3.0.html
//

#import <XCTest/XCTest.h>
#import <TungstenCrypto/TungstenCrypto-Swift.h>

@interface InitKeysTests : XCTestCase

@property int idA;
@property int idB;
@property NSString* stringIdC;
@property NSString* stringIdD;



@property KeyPair* pairA;
@property NSData* dataA;
@property NSData* dataB;
@property NSData* dataC;
@property NSData* dataD;
@property NSDate* dateA;
@end


@implementation InitKeysTests

-(void)setUp {
    [super setUp];
    _idA = 2;
    _idB = 8;
    _stringIdC = @"12";
    _stringIdD = @"421";
    _dataA = [[NSData alloc]initWithBase64EncodedString: @"dGVzdA==" options:0];
    _dataB = [[NSData alloc]initWithBase64EncodedString: @"dGVzdHRlc3Q=" options:0];
    _dataC = [[NSData alloc]initWithBase64EncodedString: @"dGVzdHRlc3R0ZXN0" options:0];
    _dataD = [[NSData alloc]initWithBase64EncodedString: @"dGVzdHRlc3R0ZXN0dGVzdA==" options:0];
    _dateA = [NSDate date];
    _pairA = [[KeyPair alloc]initWithPrivateKey:_dataA publicKey:_dataB];
}

-(void)tearDown {
    [super tearDown];
}

-(void)testInitKeyCreation {
    InitKeyRecord* initKey = [[InitKeyRecord alloc]initWithId:self.idA keyPair: self.pairA];
    
    XCTAssertEqual(self.idA, initKey.id);
    XCTAssertEqualObjects(self.pairA, initKey.keyPair);
}

-(void)testInitKeyEncoding {
    InitKeyRecord* initKey = [[InitKeyRecord alloc]initWithId:self.idA keyPair: self.pairA];
    
    NSMutableData* data = [NSMutableData data];
    
    NSKeyedArchiver* archiver = [[NSKeyedArchiver alloc]initForWritingWithMutableData:data];
    [archiver encodeObject:initKey forKey: @"key"];
    [archiver finishEncoding];
    
    NSKeyedUnarchiver* unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
    InitKeyRecord* unarchiveInitKey = [unarchiver decodeObjectForKey:@"key"];
    
    XCTAssertNotNil(unarchiveInitKey);
    XCTAssertEqual(initKey.id, unarchiveInitKey.id);
    XCTAssertNotNil(unarchiveInitKey.keyPair);
    XCTAssertEqualObjects(initKey.keyPair.publicKey, unarchiveInitKey.keyPair.publicKey);
}

-(void)testPendingInitKeyCreation {
    PendingInitKey* initKey = [[PendingInitKey alloc]initWithBaseKey:self.dataA initKeyId:self.idA signedInitKeyId:self.stringIdD];
    
    XCTAssertEqual(self.idA, initKey.initKeyId);
    XCTAssertEqualObjects(self.stringIdD, initKey.signedInitKeyId);
    XCTAssertEqualObjects(self.dataA, initKey.baseKey);
}

-(void)testPendingInitKeyEncoding {
    PendingInitKey* initKey = [[PendingInitKey alloc]initWithBaseKey:self.dataA initKeyId:self.idA signedInitKeyId:self.stringIdD];
    
    NSMutableData* data = [NSMutableData data];
    
    NSKeyedArchiver* archiver = [[NSKeyedArchiver alloc]initForWritingWithMutableData:data];
    [archiver encodeObject:initKey forKey: @"key"];
    [archiver finishEncoding];
    
    NSKeyedUnarchiver* unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
    PendingInitKey* unarchiveInitKey = [unarchiver decodeObjectForKey:@"key"];
    
    XCTAssertNotNil(unarchiveInitKey);
    XCTAssertEqual(initKey.initKeyId, unarchiveInitKey.initKeyId);
    XCTAssertEqualObjects(initKey.signedInitKeyId, unarchiveInitKey.signedInitKeyId);
    XCTAssertNotNil(unarchiveInitKey.baseKey);
    XCTAssertEqualObjects(initKey.baseKey, unarchiveInitKey.baseKey);
}

-(void)testSignedInitKeyCreation {
    SignedInitKeyRecord* signedInitKey = [[SignedInitKeyRecord alloc]initWithId:self.stringIdC keyPair:self.pairA signature:self.dataA generatedAt:self.dateA];
    
    XCTAssertEqualObjects(self.stringIdC, signedInitKey.id);
    XCTAssertEqualObjects(self.pairA, signedInitKey.keyPair);
    XCTAssertEqualObjects(self.dataA, signedInitKey.signature);
    XCTAssertEqualObjects(self.dateA, signedInitKey.generatedAt);
}

-(void)testSignedInitKeyEncoding {
    SignedInitKeyRecord* signedInitKey = [[SignedInitKeyRecord alloc]initWithId:self.stringIdC keyPair:self.pairA signature:self.dataA generatedAt:self.dateA];
    NSMutableData* data = [NSMutableData data];
    
    NSKeyedArchiver* archiver = [[NSKeyedArchiver alloc]initForWritingWithMutableData:data];
    [archiver encodeObject:signedInitKey forKey: @"key"];
    [archiver finishEncoding];
    
    NSKeyedUnarchiver* unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
    SignedInitKeyRecord* unarchiveSignedInitKey = [unarchiver decodeObjectForKey:@"key"];
    
    XCTAssertNotNil(unarchiveSignedInitKey);
    XCTAssertEqualObjects(signedInitKey.id, unarchiveSignedInitKey.id);
    XCTAssertNotNil(unarchiveSignedInitKey.keyPair);
    XCTAssertEqualObjects(signedInitKey.keyPair.publicKey, unarchiveSignedInitKey.keyPair.publicKey);
    
    XCTAssertEqualObjects(signedInitKey.signature, unarchiveSignedInitKey.signature);
    XCTAssertEqualObjects(signedInitKey.generatedAt, unarchiveSignedInitKey.generatedAt);
}

-(void)testInitKeyBundle {
    InitKeyBundle* bundle = [[InitKeyBundle alloc]initWithRegistrationId:self.stringIdC deviceId:self.stringIdD initKeyId:self.idA initKeyPublic:self.dataA signedInitKeyPublic:self.dataB signedInitKeyId:self.stringIdD signedInitKeySignature:self.dataC identityKey:self.dataD];
    
    XCTAssertEqualObjects(self.stringIdC, bundle.registrationId);
    XCTAssertEqualObjects(self.stringIdD, bundle.deviceId);
    XCTAssertEqual(self.idA, bundle.initKeyId);
    XCTAssertEqualObjects(self.stringIdD, bundle.signedInitKeyId);
    
    XCTAssertEqualObjects(self.dataA, bundle.initKeyPublic);
    XCTAssertEqualObjects(self.dataB, bundle.signedInitKeyPublic);
    XCTAssertEqualObjects(self.dataC, bundle.signedInitKeySignature);
    XCTAssertEqualObjects(self.dataD, bundle.identityKey);
}

-(void)testInitKeyBundleEncoding {
    InitKeyBundle* bundle = [[InitKeyBundle alloc]initWithRegistrationId:self.stringIdC deviceId:self.stringIdD initKeyId:self.idA initKeyPublic:self.dataA signedInitKeyPublic:self.dataB signedInitKeyId:self.stringIdD signedInitKeySignature:self.dataC identityKey:self.dataD];
    NSMutableData* data = [NSMutableData data];
    
    NSKeyedArchiver* archiver = [[NSKeyedArchiver alloc]initForWritingWithMutableData:data];
    [archiver encodeObject:bundle forKey: @"key"];
    [archiver finishEncoding];
    
    NSKeyedUnarchiver* unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
    InitKeyBundle* unarchivedBundle = [unarchiver decodeObjectForKey:@"key"];
    
    XCTAssertNotNil(unarchivedBundle);
 
    XCTAssertEqualObjects(unarchivedBundle.registrationId, bundle.registrationId);
    XCTAssertEqualObjects(unarchivedBundle.deviceId, bundle.deviceId);
    XCTAssertEqual(unarchivedBundle.initKeyId, bundle.initKeyId);
    XCTAssertEqualObjects(unarchivedBundle.signedInitKeyId, bundle.signedInitKeyId);
    
    XCTAssertEqualObjects(unarchivedBundle.initKeyPublic, bundle.initKeyPublic);
    XCTAssertEqualObjects(unarchivedBundle.signedInitKeyPublic, bundle.signedInitKeyPublic);
    XCTAssertEqualObjects(unarchivedBundle.signedInitKeySignature, bundle.signedInitKeySignature);
    XCTAssertEqualObjects(unarchivedBundle.identityKey, bundle.identityKey);
}

@end

//
//  Copyright © 2017 Tungsten Labs UG. All rights reserved.
//
//  Licensed according to https://www.gnu.org/licenses/gpl-3.0.html
//

#import <XCTest/XCTest.h>
#import <TungstenCrypto/TungstenCrypto-Swift.h>
#import "NSData+RandomGenerator.h"
@interface SessionRecordTests : XCTestCase

@end

@implementation SessionRecordTests

-(void)testEmptyInitializer {
    SessionRecord* sessionRecord = [[SessionRecord alloc] init];
    XCTAssertNotNil(sessionRecord);
    XCTAssertNotNil(sessionRecord.sessionState);
    XCTAssertNotNil(sessionRecord.previousStates);
    XCTAssertEqual(sessionRecord.previousStates.count, 0);
    XCTAssertEqual(sessionRecord.isFresh, true);
}

-(void)testParameteredInitializer {
    SessionState* state = [[SessionState alloc]init];
    SessionRecord* sessionRecord = [[SessionRecord alloc]initWithSessionState:state];
    
    XCTAssertNotNil(sessionRecord);
    XCTAssertNotNil(sessionRecord.sessionState);
    XCTAssertEqual(sessionRecord.sessionState, state);
    XCTAssertNotNil(sessionRecord.previousStates);
    XCTAssertEqual(sessionRecord.previousStates.count, 0);
    XCTAssertEqual(sessionRecord.isFresh, false);
}

-(void)testEncoding {
    SessionState* state1 = [[SessionState alloc]init];
    state1.version = 43;
    
    SessionState* state2 = [[SessionState alloc]init];
    state2.version = 11;
    SessionRecord* sessionRecord = [[SessionRecord alloc]initWithSessionState:state1];
    [sessionRecord promote:state2];
    
    NSMutableData* data = [NSMutableData data];
    NSKeyedArchiver* archiver = [[NSKeyedArchiver alloc]initForWritingWithMutableData:data];
    [archiver encodeObject:sessionRecord forKey: @"key"];
    [archiver finishEncoding];
    
    NSKeyedUnarchiver* unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
    SessionRecord* unarchivedSessionRecord = [unarchiver decodeObjectForKey:@"key"];

    XCTAssertNotNil(unarchivedSessionRecord);
    XCTAssertNotNil(unarchivedSessionRecord.sessionState);
    XCTAssertEqual(unarchivedSessionRecord.sessionState.version, state2.version);
    XCTAssertNotNil(unarchivedSessionRecord.previousStates);
    XCTAssertEqual(unarchivedSessionRecord.previousStates.count, 1);
    XCTAssertEqual(((SessionState*)[sessionRecord.previousStates objectAtIndex:0]).version, state1.version);
    XCTAssertEqual(unarchivedSessionRecord.isFresh, false);
}

-(void)testHasSessionState {
    SessionState* state1 = [[SessionState alloc]init];
    state1.version = 43;
    state1.aliceBaseKey =  [NSData garbageDataWithLength:32];
    SessionState* state2 = [[SessionState alloc]init];
    state2.version = 11;
    state2.aliceBaseKey = [NSData garbageDataWithLength:32];
    SessionState* state3 = [[SessionState alloc]init];
    state3.version = 54;
    state3.aliceBaseKey = [NSData garbageDataWithLength:32];
    
    SessionRecord* sessionRecord = [[SessionRecord alloc]initWithSessionState:state1];
    [sessionRecord promote:state2];

    XCTAssertTrue([sessionRecord hasSessionStateWithVersion:state1.version baseKey:state1.aliceBaseKey]);
    XCTAssertTrue([sessionRecord hasSessionStateWithVersion:state2.version baseKey:state2.aliceBaseKey]);
    XCTAssertFalse([sessionRecord hasSessionStateWithVersion:state3.version baseKey:state3.aliceBaseKey]);
}

-(void)testPromoteState {
    SessionRecord* sessionRecord = [[SessionRecord alloc]init];
    SessionState* state1 = sessionRecord.sessionState;
    SessionState* state2 = [[SessionState alloc]init];
    SessionState* state3 = [[SessionState alloc]init];
    
    [sessionRecord promote:state2];
    
    XCTAssertEqual(state1, [sessionRecord.previousStates objectAtIndex:0]);
    XCTAssertEqual(state2, sessionRecord.sessionState);
    
    [sessionRecord promote:state3];
    
    XCTAssertEqual(state1, [sessionRecord.previousStates objectAtIndex:1]);
    XCTAssertEqual(state2, [sessionRecord.previousStates objectAtIndex:0]);
    XCTAssertEqual(state3, sessionRecord.sessionState);
    
    for(int i=0; i<40; i++) {
        [sessionRecord promote:[[SessionState alloc] init]];
    }
    XCTAssertEqual(sessionRecord.previousStates.count, 40);
    XCTAssertEqual([sessionRecord.previousStates objectAtIndex:39], state3);
}

-(void)testArchiveCurrentState {
    SessionRecord* sessionRecord = [[SessionRecord alloc]init];
    SessionState* state1 = sessionRecord.sessionState;
    [sessionRecord archiveCurrentState];
    SessionState* state2 = sessionRecord.sessionState;
    [sessionRecord archiveCurrentState];
    
    XCTAssertEqual(state2, [sessionRecord.previousStates objectAtIndex:0]);
    XCTAssertEqual(state1, [sessionRecord.previousStates objectAtIndex:1]);
}

-(void)testReplaceSessions {
    SessionRecord* sessionRecord = [[SessionRecord alloc]init];
    SessionState* state1 = sessionRecord.sessionState;
    [sessionRecord archiveCurrentState];
    SessionState* state2 = sessionRecord.sessionState;
    
    SessionState* state3 = [[SessionState alloc]init];
    SessionState* state4 = [[SessionState alloc]init];

    [sessionRecord replace:state1 with:state3];
    [sessionRecord replace:state2 with:state4];
    
    XCTAssertEqual(state3, [sessionRecord.previousStates objectAtIndex:0]);
    XCTAssertEqual(state4, sessionRecord.sessionState);
}

-(void)setUp {
    [super setUp];
}

-(void)tearDown {
    [super tearDown];
}

@end

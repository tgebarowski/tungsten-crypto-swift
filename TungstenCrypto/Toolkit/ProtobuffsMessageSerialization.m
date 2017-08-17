//
//  Copyright © 2017 Tungsten Labs UG. All rights reserved.
//
//  Licensed according to https://www.gnu.org/licenses/gpl-3.0.html
//

#import "ProtobuffsMessageSerialization.h"
#import <TungstenCrypto/TungstenCrypto-Swift.h>
#import <TungstenCrypto/SecretTextProtocol.pb.h>

@implementation ProtobuffsMessageSerialization

- (NSData*)encodeMessageWithMessage:(SecretMessage*)message {
    ProtoSecretMessageBuilder* builder = [ProtoSecretMessage builder];
    [builder setCoreKey:message.senderCoreKey];
    [builder setCounter: (unsigned int) message.counter];
    [builder setCiphertext:message.cipherText];
    [builder setPreviousCounter:(unsigned int) message.previousCounter];
    
    return [[builder build] data];
}

- (SecretMessageContainer*)decodeMessageWithData:(NSData*)data error:(NSError**)error {
    ProtoSecretMessage* secretMessage;
    @try {
        secretMessage = [ProtoSecretMessage parseFromData:data];
    } @catch(NSException* exception) {
        *error = [NSError errorWithDomain:exception.name code:0 userInfo:@{NSLocalizedDescriptionKey: exception.reason}];
        return  nil;
    }
    
    SecretMessageContainer* container = [[SecretMessageContainer alloc]initWithCipherText:[secretMessage hasCiphertext] ? secretMessage.ciphertext: nil
                                                                                    counter:[secretMessage hasCounter] ? @(secretMessage.counter) : nil
                                                                            previousCounter:[secretMessage hasPreviousCounter] ? @(secretMessage.previousCounter) : nil
                                                                                 coreKey:[secretMessage hasCoreKey] ? secretMessage.coreKey: nil];
    return container;
}

- (NSData*)encodeInitKeyMessageWithInitKeyMessage:(InitKeySecretMessage*)initKeyMessage {
    ProtoInitKeySecretMessageBuilder* builder = [ProtoInitKeySecretMessage builder];
    
    [builder setSignedInitKeyId: initKeyMessage.signedInitKeyId];
    [builder setBaseKey:initKeyMessage.baseKey];
    [builder setIdentityKey:initKeyMessage.identityKey];
    [builder setMessage: initKeyMessage.message.serialized];
    [builder setRegistrationId: initKeyMessage.registrationId];
    if(initKeyMessage.initKeyID != -1) {
        [builder setInitKeyId: (unsigned int)initKeyMessage.initKeyID];
    }
    return [[builder build]data];
    
}

-(InitKeySecretMessageContainer *)decodeInitKeyMessageWithData:(NSData *)data error:(NSError *__autoreleasing  _Nullable *)error {
    ProtoInitKeySecretMessage* initKeySecretMessage;
    @try {
        initKeySecretMessage = [ProtoInitKeySecretMessage parseFromData:data];
    } @catch (NSException *exception) {
        *error = [NSError errorWithDomain:exception.name code:0 userInfo:@{NSLocalizedDescriptionKey: exception.reason}];
        return  nil;
    }
    
    InitKeySecretMessageContainer* container = [[InitKeySecretMessageContainer alloc]initWithSignedInitKeyId:initKeySecretMessage.hasSignedInitKeyId ? initKeySecretMessage.signedInitKeyId : nil
                                                                                                    baseKey:initKeySecretMessage.hasBaseKey ? initKeySecretMessage.baseKey : nil
                                                                                                identityKey:initKeySecretMessage.hasIdentityKey ? initKeySecretMessage.identityKey : nil
                                                                                                    message:initKeySecretMessage.hasMessage ? initKeySecretMessage.message : nil
                                                                                             registrationId:initKeySecretMessage.hasRegistrationId ? initKeySecretMessage.registrationId : nil
                                                                                                   initKeyId:initKeySecretMessage.hasInitKeyId ? @(initKeySecretMessage.initKeyId) : nil];
    
    return container;
}

@end

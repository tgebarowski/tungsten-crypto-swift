//
//  Copyright © 2017 Tungsten Labs UG. All rights reserved.
//
//  Licensed according to https://www.gnu.org/licenses/gpl-3.0.html
//

#import "TUNAes256GcmAuthenticatedCiphertextComposer.h"

NSString * const TUNAes256GcmAuthenticatedCiphertextComposerCiphertextKey = @"TUNAes256GcmAuthenticatedCiphertextComposerCiphertextKey";
NSString * const TUNAes256GcmAuthenticatedCiphertextComposerAuthTagKey = @"TUNAes256GcmAuthenticatedCiphertextComposerAuthTagKey";

@interface TUNAes256GcmAuthenticatedCiphertextComposer ()
@property(nonatomic) NSUInteger authenticationTagSize;
@end

@implementation TUNAes256GcmAuthenticatedCiphertextComposer

- (instancetype)initWithAuthenticationTagSize:(NSUInteger)authenticationTagSize {
    self = [super init];
    if (self) {
        self.authenticationTagSize = authenticationTagSize;
    }

    return self;
}

- (NSDictionary *)decomposeAuthenticatedCiphertext:(NSData *)authenticatedCiphertext {
    NSAssert(self.authenticationTagSize > 0, @"Wrong authentication tag size");

    NSMutableDictionary *decoded = [NSMutableDictionary dictionary];
    
    NSRange messagePayloadRange = NSMakeRange(0, [authenticatedCiphertext length] - self.authenticationTagSize);
    NSData *messagePayloadData;
    if (messagePayloadRange.length > 0) {
        messagePayloadData = [authenticatedCiphertext subdataWithRange:messagePayloadRange];
    }

    if (messagePayloadData) {
        decoded[TUNAes256GcmAuthenticatedCiphertextComposerCiphertextKey] = messagePayloadData;
    }

    NSRange authenticationTagRange = NSMakeRange(messagePayloadRange.length, self.authenticationTagSize);
    NSData *authenticationTagData;
    if (authenticationTagRange.location + self.authenticationTagSize == authenticatedCiphertext.length) {
        authenticationTagData = [authenticatedCiphertext subdataWithRange:authenticationTagRange];
    }

    if (authenticationTagData) {
        decoded[TUNAes256GcmAuthenticatedCiphertextComposerAuthTagKey] = authenticationTagData;
    }

    return decoded;
}

- (NSData *)composeAuthenticatedCiphertextWithCiphertext:(NSData *)ciphertext authenticationTag:(NSData *)tag {
    NSAssert(tag.length == self.authenticationTagSize, @"Wrong authentication tag size");

    NSMutableData *encryptedMessageTextData = [ciphertext mutableCopy];
    
    [encryptedMessageTextData appendData:tag];
    
    return [encryptedMessageTextData copy];
}
@end

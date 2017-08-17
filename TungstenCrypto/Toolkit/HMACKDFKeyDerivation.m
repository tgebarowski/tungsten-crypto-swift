//
//  Copyright © 2017 Tungsten Labs UG. All rights reserved.
//
//  Licensed according to https://www.gnu.org/licenses/gpl-3.0.html
//

#import "HMACKDFKeyDerivation.h"
#import <CommonCrypto/CommonCrypto.h>
#import <CommonCrypto/CommonHMAC.h>
#import <TungstenCrypto/TungstenCrypto-Swift.h>
@implementation HMACKDFKeyDerivation

-(NSData *)hmacWithSeed:(NSData *)seed key:(NSData *)key {
    uint8_t result[CC_SHA256_DIGEST_LENGTH] = {0};
    CCHmacContext ctx;
    CCHmacInit(&ctx, kCCHmacAlgSHA256, [key bytes], [key length]);
    CCHmacUpdate(&ctx, [seed bytes], [seed length]);
    CCHmacFinal(&ctx, result);
    return [NSData dataWithBytes:result length:sizeof(result)];
}

- (NSData *)hmacWithSenderIdentityKey:(NSData *)senderIdentityKey receiverIdentityKey:(NSData *)receiverIdentityKey macKey:(NSData *)macKey serialized:(NSData *)serialized {
    uint8_t result[CC_SHA256_DIGEST_LENGTH] = {0};
    CCHmacContext context;
    CCHmacInit  (&context, kCCHmacAlgSHA256, [macKey bytes], [macKey length]);
    CCHmacUpdate(&context, [senderIdentityKey bytes], [senderIdentityKey length]);
    CCHmacUpdate(&context, [receiverIdentityKey bytes], [receiverIdentityKey length]);
    CCHmacUpdate(&context, [serialized bytes], [serialized length]);

    CCHmacFinal(&context, result);
    return [NSData dataWithBytes:result length:sizeof(result)];
}

- (DerivedSecrets * _Nullable)deriveKeyWithSeed:(NSData * _Nonnull)seed info:(NSData * _Nonnull)info salt:(NSData * _Nonnull)salt error:(NSError * _Nullable * _Nullable)error SWIFT_WARN_UNUSED_RESULT {    
    @try {
        NSError* localError = nil;
        NSData *derivedMaterial = [self deriveKey:seed info:info salt:salt outputSize:96 error: &localError];
        if(localError) {
            if (*error) {
                *error = localError;
            }
            return nil;
        }
        NSData *cipherKey       = [derivedMaterial subdataWithRange:NSMakeRange(0, 32)];
        NSData *macKey          = [derivedMaterial subdataWithRange:NSMakeRange(32, 32)];
        NSData *iv              = [derivedMaterial subdataWithRange:NSMakeRange(64, 16)];
        
        return [[DerivedSecrets alloc]initWithCipherKey:cipherKey macKey:macKey iv:iv];
    }
    @catch (NSException *exception) {
        if(error) {
            *error = [NSError errorWithDomain:MulticastError.domain
                                         code:MulticastError.keyDerivationErrorCode
                                     userInfo:exception.userInfo];
        }
        return nil;
    }
}

- (NSData *)deriveKey:(NSData *)seed info:(NSData *)info salt:(NSData *)salt outputSize:(size_t)outputSize error:(NSError**)error {
    return [HMACKDFKeyDerivation deriveKey:seed info:info salt:salt outputSize:outputSize offset:1 error: error];
}

+ (NSData *)deriveKey:(NSData *)seed info:(NSData *)info salt:(NSData *)salt outputSize:(size_t)outputSize offset:(size_t)offset error:(NSError**)error {
    NSData *prk = [self extract:seed salt:salt];
    NSData *okm = [self expand:prk info:info outputSize:outputSize offset:offset error: error];
    return okm;
}

+ (NSData*)extract:(NSData*)data salt:(NSData*)salt{
    char prk[CC_SHA256_DIGEST_LENGTH] = {0};
    CCHmac(kCCHmacAlgSHA256, [salt bytes], [salt length], [data bytes], [data length], prk);
    return [NSData dataWithBytes:prk length:sizeof(prk)];
}

+ (NSData*)expand:(NSData*)data info:(NSData*)info outputSize:(size_t)outputSize offset:(size_t)offset error:(NSError**)error {
    int             iterations = (int)ceil((double)outputSize/(double)kCCHmacAlgSHA256);
    NSData          *mixin = [NSData data];
    NSMutableData   *results = [NSMutableData data];
    
    
    if((SIZE_T_MAX - iterations) < offset) {
        if(error) {
            *error = [NSError errorWithDomain:MulticastError.domain
                                         code:MulticastError.keyDerivationErrorCode
                                     userInfo:@{NSLocalizedDescriptionKey:@"offset and iterations are bigger then SIZE_T_MAX"}];
        }
        return nil;
    }
    
    for (size_t i=offset; i<(iterations+offset); i++) {
        CCHmacContext ctx;
        CCHmacInit(&ctx, kCCHmacAlgSHA256, [data bytes], [data length]);
        CCHmacUpdate(&ctx, [mixin bytes], [mixin length]);
        if (info != nil) {
            CCHmacUpdate(&ctx, [info bytes], [info length]);
        }
        unsigned char c = i;
        CCHmacUpdate(&ctx, &c, 1);
        unsigned char T[CC_SHA256_DIGEST_LENGTH];
        CCHmacFinal(&ctx, T);
        NSData *stepResult = [NSData dataWithBytes:T length:sizeof(T)];
        [results appendData:stepResult];
        mixin = [stepResult copy];
    }
    
    return [[NSData dataWithData:results] subdataWithRange:NSMakeRange(0, outputSize)];
}

@end

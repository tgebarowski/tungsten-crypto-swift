//
//  Copyright © 2017 Tungsten Labs UG. All rights reserved.
//
//  Licensed according to https://www.gnu.org/licenses/gpl-3.0.html
//

#import "TUNAes256GcmCipher.h"
#import "TUNAes256GcmAuthenticatedCiphertextComposer.h"
#import <TungstenCrypto/TungstenCrypto-Swift.h>

#include <openssl/rand.h>
#include <openssl/err.h>
#include <openssl/pem.h>

NSUInteger const TUNAes256KeySize = 32;
NSUInteger const TUNAes256AuthenticationTagSize = 16; // max size of auth tag in gcm

/*
 * References:
 * https://wiki.openssl.org/index.php/EVP_Authenticated_Encryption_and_Decryption#Authenticated_Decryption_using_GCM_mode
 * https://github.com/openssl/openssl/blob/master/demos/evp/aesgcm.c
 */

@interface TUNAes256GcmCipher ()

@property (nonatomic, strong) NSData *aad;
@property(nonatomic, strong) TUNAes256GcmAuthenticatedCiphertextComposer *ciphertextComposer;

@end

@implementation TUNAes256GcmCipher


- (NSData *)generateKey {
    unsigned char iv[TUNAes256KeySize];
    
    if (!RAND_bytes(iv, sizeof iv)) {
        return nil;
    }
    return [NSData dataWithBytes:iv length:sizeof iv];
}

-(NSData *)generateIV {
    unsigned char iv[EVP_MAX_IV_LENGTH];
    
    if (!RAND_bytes(iv, sizeof iv)) {
        return nil;
    }
    return [NSData dataWithBytes:iv length:sizeof iv];
}

-(NSData *)encryptWithData:(NSData *)data key:(NSData *)key iv:(NSData *)iv error:(NSError *__autoreleasing  _Nullable * _Nullable)error {
    NSMutableData *mutableCiphertext;
    unsigned char tagBuffer[TUNAes256AuthenticationTagSize] = {0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0};
    BOOL success = [self encryptPlaintext:data
                               ciphertext:&mutableCiphertext
                                      aad:self.aad
                                      key:key
                                     ivec:iv
                                      tag:tagBuffer
                                  tagSize:TUNAes256AuthenticationTagSize
                                    error:error];
    if (!success) {
        return nil;
    }
    
    NSData *outTag = [NSData dataWithBytes:tagBuffer length:TUNAes256AuthenticationTagSize];
    
    return [self.ciphertextComposer composeAuthenticatedCiphertextWithCiphertext:mutableCiphertext
                                                               authenticationTag:outTag];
}

-(NSData *)decryptWithData:(NSData *)data key:(NSData *)key iv:(NSData *)iv error:(NSError *__autoreleasing  _Nullable * _Nullable)error {
    NSDictionary *decomposedCiphertext = [self.ciphertextComposer decomposeAuthenticatedCiphertext:data];
    NSData *messagePayloadData = decomposedCiphertext[TUNAes256GcmAuthenticatedCiphertextComposerCiphertextKey];
    NSData *authenticationTagData = decomposedCiphertext[TUNAes256GcmAuthenticatedCiphertextComposerAuthTagKey];
    
    NSMutableData *mutablePlaintext;
    BOOL success = [self decryptCiphertext:messagePayloadData
                                 plaintext:&mutablePlaintext
                                       aad:self.aad
                                       key:key
                                      ivec:iv
                                       tag:authenticationTagData
                                     error:error];
    if (!success) {
        return nil;
    }
    
    return [mutablePlaintext copy];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        unsigned char gcm_aad[] = {
            0x4d, 0x23, 0xc3, 0xce,
            0xc3, 0x34, 0xb4, 0x9b,
            0xdb, 0x37, 0x0c, 0x43,
            0x7f, 0xec, 0x78, 0xde
        };
        self.aad = [NSData dataWithBytes:gcm_aad length:sizeof(gcm_aad)];
        self.ciphertextComposer = [[TUNAes256GcmAuthenticatedCiphertextComposer alloc] initWithAuthenticationTagSize:TUNAes256AuthenticationTagSize];
    }
    return self;
}

#pragma mark - Private

/* Encrypt plaintext
 * Required: key, ivec, tag
 * Optional: aad
 */
- (BOOL)encryptPlaintext:(NSData *)plaintext
              ciphertext:(NSMutableData **)ciphertext
                     aad:(NSData *)aad
                     key:(NSData *)key
                    ivec:(NSData *)ivec
                     tag:(unsigned char *)tag
                 tagSize:(int)tagSize
                   error:(NSError **)error {

    if (ivec.length > EVP_MAX_IV_LENGTH) {
        if (error) {
            *error = [self errorWithCode:TUNAes256GcmCryptoErrors.iVExceedsMaxLengthErrorCode
                                 details:@"IV exceedes max length"];
        }
        return NO;
    }
    
    if (key.length > EVP_MAX_KEY_LENGTH) {
        if (error) {
            *error = [self errorWithCode:TUNAes256GcmCryptoErrors.keyExceedsMaxLengthErrorCode
                                 details:@"Key exceedes max length"];
        }
        return NO;
    }
    
    if (plaintext.length > INT_MAX) {
        if (error) {
            *error = [self errorWithCode:TUNAes256GcmCryptoErrors.unableToEncryptErrorCode
                                 details:@"Plain text is to big"];
        }
        return NO;
    }
    
    if (aad.length > INT_MAX) {
        if (error) {
            *error = [self errorWithCode:TUNAes256GcmCryptoErrors.unableToEncryptErrorCode
                                 details:@"Cipher text is to big"];
        }
        return NO;
    }
    
    const unsigned char *cKey = [key bytes];
    const unsigned char *cIVec = [ivec bytes];
    
    NSError *localError;
    *ciphertext = [NSMutableData dataWithLength:[plaintext length]];
    if (! *ciphertext) {
        return NO;
    }

    // set up to Encrypt AES 256 GCM
    int numberOfBytes = 0;
    
    EVP_CIPHER_CTX *ctx;
    
    /* Create and initialise the context */
    if(!(ctx = EVP_CIPHER_CTX_new())) {
        localError = [self unableToEncryptError];
        if(error) {
            *error = localError;
        }
        return NO;
    }
    
    /* Initialise the encryption operation. */
    if(1 != EVP_EncryptInit_ex(ctx, EVP_aes_256_gcm(), NULL, NULL, NULL)) {
        localError = [self unableToEncryptError];
        if(error) {
            *error = localError;
        }
        return NO;
    }
    
    /* Set IV length if default 12 bytes (96 bits) is not appropriate */
    if(1 != EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_GCM_SET_IVLEN, (int)ivec.length, NULL)) {
        localError = [self unableToEncryptError];
        if(error) {
            *error = localError;
        }
        return NO;
    }
    
    /* Initialise key and IV */
    if(1 != EVP_EncryptInit_ex(ctx, NULL, NULL, cKey, cIVec)) {
        localError = [self unableToEncryptError];
        if(error) {
            *error = localError;
        }
        return NO;
    }
    
    /* Provide any AAD data. This can be called zero or more times as
     * required
     */
    if (aad) {
        if (1 != EVP_EncryptUpdate(ctx, NULL, &numberOfBytes, [aad bytes], (int)[aad length])) {
            localError = [self unableToEncryptError];
            if(error) {
                *error = localError;
            }
            return NO;
        }
    }

    unsigned char *ctBytes = [*ciphertext mutableBytes];
    
    /* Provide the message to be encrypted, and obtain the encrypted output.
     * EVP_EncryptUpdate can be called multiple times if necessary
     */
    if (1 != EVP_EncryptUpdate(ctx, ctBytes, &numberOfBytes, [plaintext bytes], (int)[plaintext length])) {
        localError = [self unableToEncryptError];
        if(error) {
            *error = localError;
        }
        return NO;
    }
    
    /* Finalise the encryption. Normally ciphertext bytes may be written at
     * this stage, but this does not occur in GCM mode
     */
    if(1 != EVP_EncryptFinal_ex(ctx, ctBytes+numberOfBytes, &numberOfBytes)) {
        localError = [self unableToEncryptError];
        if(error) {
            *error = localError;
        }
        return NO;
    }

    /* Get the tag */
    if (tag) {
        if(1 != EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_GCM_GET_TAG, tagSize, tag)) {
            localError = [self unableToEncryptError];
            if(error) {
                *error = localError;
            }
            return NO;
        }
    } else {
        localError = [self errorWithCode:TUNAes256GcmCryptoErrors.tagNotProvidedErrorCode details:@"Tag not provided!"];
        if(error) {
            *error = localError;
        }
        return NO;
    }
    
    ERR_print_errors_fp(stderr);
    
    /* Clean up */
    EVP_CIPHER_CTX_free(ctx);
    
    if (error && localError) {
        *error = localError;
    }
    
    return !localError;
}

/* Decrypt ciphertext
 * Required: key, ivec, tag
 * Optional: aad
 */
- (BOOL)decryptCiphertext:(NSData *)ciphertext
                plaintext:(NSMutableData **)plaintext
                      aad:(NSData *)aad
                      key:(NSData *)key
                     ivec:(NSData *)ivec
                      tag:(NSData *)tag
                    error:(NSError **)error {

    if (!ciphertext || !plaintext || !key || !ivec) {
        return NO;
    }
    
    if (ivec.length > EVP_MAX_IV_LENGTH) {
        if (error) {
            *error = [self errorWithCode: TUNAes256GcmCryptoErrors.iVExceedsMaxLengthErrorCode
                                 details:@"IV exceedes max length"];
        }
        return NO;
    }
    
    if (key.length > EVP_MAX_KEY_LENGTH) {
        if (error) {
            *error = [self errorWithCode:TUNAes256GcmCryptoErrors.keyExceedsMaxLengthErrorCode
                                 details:@"Key exceedes max length"];
        }
        return NO;
    }
    
    if (ciphertext.length > INT_MAX) {
        if (error) {
            *error = [self errorWithCode:TUNAes256GcmCryptoErrors.unableToDecryptErrorCode
                                 details:@"Cipher text is to big"];
        }
        return NO;
    }
    
    if (aad.length > INT_MAX) {
        if (error) {
            *error = [self errorWithCode:TUNAes256GcmCryptoErrors.unableToDecryptErrorCode
                                 details:@"Cipher text is to big"];
        }
        return NO;
    }
    
    
        
    const unsigned char *cKey = [key bytes];
    const unsigned char *cIVec = [ivec bytes];
    const void *cTag = [tag bytes];

    *plaintext = [NSMutableData dataWithLength:[ciphertext length]];
    
    // set up to Decrypt AES 256 GCM
    int numberOfBytes = 0;
    
    NSError *localError;
    
    EVP_CIPHER_CTX *ctx;
    /* Create and initialise the context */
    if(!(ctx = EVP_CIPHER_CTX_new())) {
        localError = [self unableToDecryptError];
        if(error) {
            *error = localError;
        }
        return NO;
    }
    
    /* Initialise the decryption operation. */
    if(!EVP_DecryptInit_ex (ctx, EVP_aes_256_gcm(), NULL, NULL, NULL)) {
        localError = [self unableToDecryptError];
        if(error) {
            *error = localError;
        }
        return NO;
    }

    /* Set IV length. Not necessary if this is 12 bytes (96 bits) */
    if(!EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_GCM_SET_IVLEN, (int)ivec.length, NULL)) {
        localError = [self unableToDecryptError];
        if(error) {
            *error = localError;
        }
        return NO;
    }
    
    /* Initialise key and IV */
    if(!EVP_DecryptInit_ex(ctx, NULL, NULL, cKey, cIVec)) {
        localError = [self unableToDecryptError];
        if(error) {
            *error = localError;
        }
        return NO;
    }
    
    /* Add optional AAD (Additional Auth Data) */
    if (aad) {
        if(!EVP_DecryptUpdate(ctx, NULL, &numberOfBytes, [aad bytes], (int)[aad length])) {
            localError = [self unableToDecryptError];
            if(error) {
                *error = localError;
            }
            return NO;
        }
    }
    
    unsigned char *plaintextMutableBytes = (unsigned char *)[*plaintext mutableBytes];
    
    
    if(!EVP_DecryptUpdate(ctx, plaintextMutableBytes, &numberOfBytes, [ciphertext bytes], (int)[ciphertext length])) {
        localError = [self unableToDecryptError];
        if(error) {
            *error = localError;
        }
        return NO;
    }
    
    /* Set the tag */
    if (tag) {
        if(!EVP_CIPHER_CTX_ctrl(ctx, EVP_CTRL_GCM_SET_TAG, (int)tag.length, (void *)cTag)) {
            localError = [self unableToDecryptError];
            if(error) {
                *error = localError;
            }
            return NO;
        }
    } else {
        localError = [self errorWithCode:TUNAes256GcmCryptoErrors.tagNotProvidedErrorCode details:@"Tag not provided!"];
        if(error) {
            *error = localError;
        }
        return NO;
    }
    
    if (error && localError) {
        *error = localError;
    }
    
    int ret = EVP_DecryptFinal_ex(ctx, plaintextMutableBytes + numberOfBytes, &numberOfBytes);
    
    ERR_print_errors_fp(stderr);

    EVP_CIPHER_CTX_free(ctx);
    
    if(ret > 0) {
        /* Success */
        return YES;
    } else {
        if (error) {
            *error = [self errorWithCode:TUNAes256GcmCryptoErrors.verificationFailedErrorCode details:@"Ciphertext verification failed!"];
        }
        /* Verify failed */
        return NO;
    }
}

#pragma mark - Helpers

- (NSError *)unableToEncryptError {
    return [NSError errorWithDomain:TUNAes256GcmCryptoErrors.domain
                               code:TUNAes256GcmCryptoErrors.unableToEncryptErrorCode
                           userInfo:@{@"error": @"Encryption operation failure"}];
}

- (NSError *)unableToDecryptError {
    return [NSError errorWithDomain:TUNAes256GcmCryptoErrors.domain
                               code:TUNAes256GcmCryptoErrors.unableToDecryptErrorCode
                           userInfo:@{@"error": @"Decryption operation failure"}];
}

- (NSError *)errorWithCode:(NSUInteger)code details:(NSString *)details {
    return [NSError errorWithDomain:TUNAes256GcmCryptoErrors.domain
                               code:code
                           userInfo:@{@"error": [NSString stringWithFormat:@"%@", details]}];
}

@end

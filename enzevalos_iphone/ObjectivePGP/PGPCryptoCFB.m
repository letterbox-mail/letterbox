//
//  PGPCryptoCFB.m
//  ObjectivePGP
//
//  Created by Marcin Krzyzanowski on 05/06/14.
//  Copyright (c) 2014 Marcin Krzyżanowski. All rights reserved.
//

#import "PGPCryptoCFB.h"
#import "NSData+PGPUtils.h"
#import "PGPCryptoUtils.h"
#import "PGPS2K.h"
#import "PGPTypes.h"
#import "PGPMacros+Private.h"

#import <CommonCrypto/CommonCrypto.h>
#import <CommonCrypto/CommonCryptor.h>
#import <CommonCrypto/CommonDigest.h>

#import <openssl/aes.h>
#import <openssl/blowfish.h>
#import <openssl/camellia.h>
#import <openssl/cast.h>
#import <openssl/des.h>
#import <openssl/idea.h>
#import <openssl/sha.h>

NS_ASSUME_NONNULL_BEGIN

@implementation PGPCryptoCFB

+ (nullable NSData *)decryptData:(NSData *)encryptedData
                  sessionKeyData:(NSData *)sessionKeyData // s2k produceSessionKeyWithPassphrase
              symmetricAlgorithm:(PGPSymmetricAlgorithm)symmetricAlgorithm
                              iv:(NSData *)ivData {
    return [self manipulateData:encryptedData sessionKeyData:sessionKeyData symmetricAlgorithm:symmetricAlgorithm iv:ivData decrypt:YES];
}

+ (nullable NSData *)encryptData:(NSData *)encryptedData
                  sessionKeyData:(NSData *)sessionKeyData // s2k produceSessionKeyWithPassphrase
              symmetricAlgorithm:(PGPSymmetricAlgorithm)symmetricAlgorithm
                              iv:(NSData *)ivData {
    return [self manipulateData:encryptedData sessionKeyData:sessionKeyData symmetricAlgorithm:symmetricAlgorithm iv:ivData decrypt:NO];
}

#pragma mark - Private

// key binary string representation of key to be used to decrypt the ciphertext.
+ (nullable NSData *)manipulateData:(NSData *)encryptedData
                     sessionKeyData:(NSData *)sessionKeyData // s2k produceSessionKeyWithPassphrase
                 symmetricAlgorithm:(PGPSymmetricAlgorithm)symmetricAlgorithm
                                 iv:(NSData *)ivData
                            decrypt:(BOOL)decrypt {
    NSAssert(sessionKeyData.length > 0, @"Missing session key");
    NSAssert(encryptedData.length > 0, @"Missing data");
    NSAssert(ivData.length > 0, @"Missing IV");

    if (ivData.length == 0 || sessionKeyData.length == 0 || encryptedData.length == 0) {
        return nil;
    }

    NSUInteger keySize = [PGPCryptoUtils keySizeOfSymmetricAlgorithm:symmetricAlgorithm];
    NSAssert(keySize <= 32, @"Invalid key size");
    NSAssert(sessionKeyData.length >= keySize, @"Invalid session key.");

    unsigned char *iv = calloc(1, ivData.length);
    pgp_defer { if (iv) { free(iv); } };
    if (!iv) {
        return nil;
    }
    memcpy(iv, ivData.bytes, ivData.length);

    let encryptedBytes = encryptedData.bytes;
    NSUInteger outBufferLength = encryptedData.length;
    UInt8 *outBuffer = calloc(outBufferLength, sizeof(UInt8));
    pgp_defer { if (outBuffer) { free(outBuffer); } };

    NSData *decryptedData = nil;

    // decrypt with CFB
    switch (symmetricAlgorithm) {
        case PGPSymmetricAES128:
        case PGPSymmetricAES192:
        case PGPSymmetricAES256: {
            AES_KEY aes_key;
            AES_set_encrypt_key(sessionKeyData.bytes, MIN((unsigned int)keySize * 8, (unsigned int)sessionKeyData.length * 8), &aes_key);

            int blocksNum = 0;
            AES_cfb128_encrypt(encryptedBytes, outBuffer, outBufferLength, &aes_key, iv, &blocksNum, decrypt ? AES_DECRYPT : AES_ENCRYPT);
            decryptedData = [NSData dataWithBytes:outBuffer length:outBufferLength];

            memset(&aes_key, 0, sizeof(AES_KEY));
        } break;
        case PGPSymmetricIDEA: {
            IDEA_KEY_SCHEDULE encrypt_key;
            idea_set_encrypt_key(sessionKeyData.bytes, &encrypt_key);

            IDEA_KEY_SCHEDULE decrypt_key;
            idea_set_decrypt_key(&encrypt_key, &decrypt_key);

            int num = 0;
            idea_cfb64_encrypt(encryptedBytes, outBuffer, outBufferLength, decrypt ? &decrypt_key : &encrypt_key, iv, &num, decrypt ? CAST_DECRYPT : CAST_ENCRYPT);
            decryptedData = [NSData dataWithBytes:outBuffer length:outBufferLength];

            memset(&encrypt_key, 0, sizeof(IDEA_KEY_SCHEDULE));
            memset(&decrypt_key, 0, sizeof(IDEA_KEY_SCHEDULE));
        } break;
        case PGPSymmetricTripleDES: {
            DES_key_schedule *keys = calloc(3, sizeof(DES_key_schedule));
            pgp_defer { if (keys) { free(keys); } };

            for (NSUInteger n = 0; n < 3; ++n) {
                DES_set_key((DES_cblock *)(void *)(sessionKeyData.bytes + n * 8), &keys[n]);
            }

            int blocksNum = 0;
            DES_ede3_cfb64_encrypt(encryptedBytes, outBuffer, outBufferLength, &keys[0], &keys[1], &keys[2], (DES_cblock *)(void *)iv, &blocksNum, decrypt ? DES_DECRYPT : DES_ENCRYPT);
            decryptedData = [NSData dataWithBytes:outBuffer length:outBufferLength];

            if (keys) {
                memset(keys, 0, 3 * sizeof(DES_key_schedule));
            }
        } break;
        case PGPSymmetricCAST5: {
            // initialize
            CAST_KEY encrypt_key;
            CAST_set_key(&encrypt_key, MIN((unsigned int)keySize, (unsigned int)sessionKeyData.length), sessionKeyData.bytes);

            // see __ops_decrypt_init block_encrypt siv,civ,iv comments. siv is needed for weird v3 resync,
            // wtf civ ???
            // CAST_ecb_encrypt(in, out, encrypt_key, CAST_ENCRYPT);
            int num = 0; //	how much of the 64bit block we have used
            CAST_cfb64_encrypt(encryptedBytes, outBuffer, outBufferLength, &encrypt_key, iv, &num, decrypt ? CAST_DECRYPT : CAST_ENCRYPT);
            decryptedData = [NSData dataWithBytes:outBuffer length:outBufferLength];

            memset(&encrypt_key, 0, sizeof(CAST_KEY));
        } break;
        case PGPSymmetricBlowfish:
        case PGPSymmetricTwofish256:
            // TODO: implement blowfish and twofish
            [NSException raise:@"PGPNotSupported" format:@"Twofish not supported"];
            break;
        case PGPSymmetricPlaintext:
            [NSException raise:@"PGPInconsistency" format:@"Can't decrypt plaintext"];
            break;
        default:
            break;
    }

    if (outBuffer) {
        memset(outBuffer, 0, outBufferLength);
    }

    return [decryptedData copy];
}

@end

NS_ASSUME_NONNULL_END

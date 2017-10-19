//
//  PGPSymmetricKeyEncryptedSessionKeyPacket.m
//  ObjectivePGP
//
//  Created by Oliver Wiese on 11.10.17.
//  Copyright © 2017 Marcin Krzyżanowski. All rights reserved.
//
//  5.3.  Symmetric-Key Encrypted Session Key Packets (Tag 3)

#import "PGPSymmetricKeyEncryptedSessionKeyPacket.h"
#import "NSData+PGPUtils.h"
#import "PGPCryptoUtils.h"
#import "PGPMacros+Private.h"
#import "PGPPKCSEme.h"
#import "NSMutableData+PGPUtils.h"

NS_ASSUME_NONNULL_BEGIN

@interface PGPSymmetricKeyEncryptedSessionKeyPacket ()


@end

@implementation PGPSymmetricKeyEncryptedSessionKeyPacket

- (instancetype)init {
    if (self = [super init]) {
        _version = 4;
        _symmetricKeyAlgorithm = PGPSymmetricAES128;
        _s2k = [[PGPS2K alloc] initWithSpecifier:PGPS2KSpecifierSimple hashAlgorithm:PGPHashSHA256];
    }
    return self;
}

- (PGPPacketTag)tag {
    return PGPSymetricKeyEncryptedSessionKeyPacketTag; // 3
}

- (NSUInteger)parsePacketBody:(NSData *)packetBody error:(NSError *__autoreleasing *)error {
    NSUInteger position = [super parsePacketBody:packetBody error:error];
    // - A one-octet number giving the version number of the packet type. The currently defined value for packet version is 4.
    [packetBody getBytes:&_version range:(NSRange){position, 1}];
    NSAssert(self.version == 4, @"The currently defined value for packet version is 4");
    position = position + 1;
    
    // - A one-octet number giving the public-key algorithm used.
    [packetBody getBytes:&_symmetricKeyAlgorithm range:(NSRange){position, 1}];
    NSAssert(self.symmetricKeyAlgorithm == PGPSymmetricAES128, @"Not supported.");
    position = position + 1;
    // S2K
    NSUInteger s2kParsedLength = 0;
    self.s2k = [PGPS2K S2KFromData:packetBody atPosition:position length:&s2kParsedLength];
    position = position + s2kParsedLength;

    NSUInteger sessionKeySize = [PGPCryptoUtils keySizeOfSymmetricAlgorithm:self.symmetricKeyAlgorithm];
    if (sessionKeySize == NSNotFound) {
        if (error) {
            *error = [NSError errorWithDomain:PGPErrorDomain code:0 userInfo:@{ NSLocalizedDescriptionKey: @"Invalid session key size" }];
        }
       
    }
    
    return position;
}

#pragma mark - PGPExportable

- (nullable NSData *)export:(NSError *__autoreleasing  _Nullable *)error {
    
    let bodyData = [NSMutableData data];
    NSError *exportError = nil;
    let exportS2K = [self.s2k export:&exportError];
    NSAssert(!exportError, @"export failed");

    [bodyData appendBytes:&_version length:1]; //1
    [bodyData appendBytes:&_symmetricKeyAlgorithm length:1]; // 1
    [bodyData pgp_appendData:exportS2K]; // 2
    
    return [PGPPacket buildPacketOfType:self.tag withBody:^NSData * {
        return bodyData;
    }];
}

#pragma mark - NSCopying

- (instancetype)copyWithZone:(nullable NSZone *)zone {
    PGPSymmetricKeyEncryptedSessionKeyPacket *copy = [super copyWithZone:zone];
    copy->_version = self.version;
    copy->_symmetricKeyAlgorithm = self.symmetricKeyAlgorithm;
    copy-> _s2k = self.s2k;
    return copy;
}



@end

NS_ASSUME_NONNULL_END



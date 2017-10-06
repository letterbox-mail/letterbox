//
//  PGPSignatureSubPacket.m
//  ObjectivePGP
//
//  Created by Marcin Krzyzanowski on 04/05/14.
//  Copyright (c) 2014 Marcin Krzyżanowski. All rights reserved.
//

#import "PGPSignatureSubpacket.h"
#import "PGPSignatureSubpacket+Private.h"
#import "PGPSignatureSubpacketCreationTime.h"
#import "PGPSignatureSubpacketHeader.h"
#import "PGPCompressedPacket.h"
#import "PGPKeyID.h"
#import "PGPPacket.h"
#import "PGPPacket+Private.h"
#import "NSMutableData+PGPUtils.h"

#import "PGPLogging.h"
#import "PGPMacros+Private.h"

NS_ASSUME_NONNULL_BEGIN

@interface PGPSignatureSubpacket ()

@property (nonatomic, readwrite) NSUInteger length;
@end

@implementation PGPSignatureSubpacket

- (instancetype)initWithType:(PGPSignatureSubpacketType)type andValue:(id)value {
    if ((self = [super init])) {
        _type = type;
        _value = value;
    }
    return self;
}

- (instancetype)initWithHeader:(PGPSignatureSubpacketHeader *)header body:(NSData *)subPacketBodyData {
    if (self = [self initWithType:header.type andValue:NSNull.null]) {
        _length = header.headerLength + header.bodyLength;
        [self parseSubpacketBody:subPacketBodyData];
    }
    return self;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@ %@ %@", [super description], @(self.type), self.value];
}

/**
 *  5.2.3.1.  Signature Subpacket Specification
 *
 *  @param packetBody A single subpacket body data.
 */
- (void)parseSubpacketBody:(NSData *)packetBodyData {
    //PGPLogDebug(@"parseSubpacketBody %@, body %@",@(self.type), packetBodyData);

    switch (self.type & 0x7F) {
        case PGPSignatureSubpacketTypeSignatureCreationTime: // NSDate
        {
            //  5.2.3.4.  Signature Creation Time
            //  Signature Creation Time MUST be present in the hashed area.
            self.value = [PGPSignatureSubpacketCreationTime packetWithData:packetBodyData].value;
        } break;
        case PGPSignatureSubpacketTypeSignatureExpirationTime: // NSNumber
        case PGPSignatureSubpacketTypeKeyExpirationTime: {
            //  5.2.3.10. Signature Expiration Time
            //  5.2.3.6.  Key Expiration Time
            //   The validity period of the signature
            UInt32 validityPeriodTime = 0;
            [packetBodyData getBytes:&validityPeriodTime length:4];
            validityPeriodTime = CFSwapInt32BigToHost(validityPeriodTime);
            self.value = @(validityPeriodTime);
        } break;
        case PGPSignatureSubpacketTypeTrustSignature: {
            // (1 octet "level" (depth), 1 octet of trust amount)
            // TODO trust subpacket
        } break;
        case PGPSignatureSubpacketTypeIssuerKeyID: // PGPKeyID
        {
            //  5.2.3.5.  Issuer

            PGPKeyID *keyID = [[PGPKeyID alloc] initWithLongKey:packetBodyData];
            self.value = keyID; //[packetBody subdataWithRange:(NSRange){0,8}];
        } break;
        case PGPSignatureSubpacketTypeExportableCertification: // NSNumber BOOL
        {
            // 5.2.3.11.  Exportable Certification
            UInt8 exportableValue = 0;
            [packetBodyData getBytes:&exportableValue length:1];
            self.value = @(exportableValue);
        } break;
        case PGPSignatureSubpacketTypePrimaryUserID: // NSNumber BOOL
        {
            // 5.2.3.19.  Primary User ID
            UInt8 primaryUserIDValue = 0;
            [packetBodyData getBytes:&primaryUserIDValue length:1];
            self.value = @(primaryUserIDValue);
        } break;
        case PGPSignatureSubpacketTypeSignerUserID: // NSString
        // side note: This subpacket is not appropriate to use to refer to a User Attribute packet.
        case PGPSignatureSubpacketTypePreferredKeyServer: // NSString
        case PGPSignatureSubpacketTypePolicyURI: // NSString
        {
            self.value = [[NSString alloc] initWithData:packetBodyData encoding:NSUTF8StringEncoding];
        } break;
        case PGPSignatureSubpacketTypeReasonForRevocation: // NSNumber
        {
            UInt8 revocationCode = 0;
            [packetBodyData getBytes:&revocationCode length:1];
            self.value = @(revocationCode);
        } break;
        case PGPSignatureSubpacketTypeKeyFlags: // NSArray of NSNumber
        {
            //  5.2.3.21.  Key Flags
            //  (N octets of flags) ???
            //  This implementation supports max 8 octets (64bit)
            UInt64 flagByte = 0;
            [packetBodyData getBytes:&flagByte length:MIN((NSUInteger)8, packetBodyData.length)];
            NSMutableArray *flagsArray = [NSMutableArray array];

            if (flagByte & PGPSignatureFlagAllowCertifyOtherKeys) {
                [flagsArray addObject:@(PGPSignatureFlagAllowCertifyOtherKeys)];
            }
            if (flagByte & PGPSignatureFlagAllowSignData) {
                [flagsArray addObject:@(PGPSignatureFlagAllowSignData)];
            }
            if (flagByte & PGPSignatureFlagAllowEncryptCommunications) {
                [flagsArray addObject:@(PGPSignatureFlagAllowEncryptCommunications)];
            }
            if (flagByte & PGPSignatureFlagAllowEncryptStorage) {
                [flagsArray addObject:@(PGPSignatureFlagAllowEncryptStorage)];
            }
            if (flagByte & PGPSignatureFlagSecretComponentMayBeSplit) {
                [flagsArray addObject:@(PGPSignatureFlagSecretComponentMayBeSplit)];
            }
            if (flagByte & PGPSignatureFlagAllowAuthentication) {
                [flagsArray addObject:@(PGPSignatureFlagAllowAuthentication)];
            }
            if (flagByte & PGPSignatureFlagPrivateKeyMayBeInThePossesionOfManyPersons) {
                [flagsArray addObject:@(PGPSignatureFlagPrivateKeyMayBeInThePossesionOfManyPersons)];
            }

            self.value = [flagsArray copy];
        } break;
        case PGPSignatureSubpacketTypePreferredSymetricAlgorithm: // NSArray of NSNumber(PGPSymmetricAlgorithm)
        {
            // 5.2.3.7.  Preferred Symmetric Algorithms
            NSMutableArray *algorithmsArray = [NSMutableArray array];

            for (NSUInteger i = 0; i < packetBodyData.length; i++) {
                PGPSymmetricAlgorithm algorithm = PGPSymmetricPlaintext;
                [packetBodyData getBytes:&algorithm range:(NSRange){i, 1}];
                [algorithmsArray addObject:@(algorithm)];
            }

            self.value = [algorithmsArray copy];
        } break;
        case PGPSignatureSubpacketTypePreferredHashAlgorithm: // NSArray of NSNumber(PGPHashAlgorithm)
        {
            // 5.2.3.8.  Preferred Hash Algorithms
            let algorithmsArray = [NSMutableArray<NSNumber *> array];

            for (NSUInteger i = 0; i < packetBodyData.length; i++) {
                PGPHashAlgorithm algorithm = PGPHashUnknown;
                [packetBodyData getBytes:&algorithm range:(NSRange){i, 1}];
                [algorithmsArray addObject:@(algorithm)];
            }

            self.value = algorithmsArray;
        } break;
        case PGPSignatureSubpacketTypePreferredCompressionAlgorithm: // NSArray of NSNumber(PGPCompressionAlgorithm)
        {
            // 5.2.3.9.  Preferred Compression Algorithms
            // If this subpacket is not included, ZIP is preferred.
            NSMutableArray *algorithmsArray = [NSMutableArray array];

            for (UInt8 i = 0; i < packetBodyData.length; i++) {
                PGPCompressionAlgorithm algorithm = PGPCompressionUncompressed;
                [packetBodyData getBytes:&algorithm range:(NSRange){i, 1}];
                [algorithmsArray addObject:@(algorithm)];
            }

            self.value = [algorithmsArray copy];
        } break;
        case PGPSignatureSubpacketTypeKeyServerPreference: // NSArray of NSNumber(PGPKeyServerPreferenceFlags)
        {
            // 5.2.3.17.  Key Server Preferences
            PGPKeyServerPreferenceFlags flag = PGPKeyServerPreferenceUnknown;
            [packetBodyData getBytes:&flag length:MIN((NSUInteger)8, packetBodyData.length)];

            NSMutableArray *flagsArray = [NSMutableArray array];
            if (flag & PGPKeyServerPreferenceNoModify) {
                [flagsArray addObject:@(PGPKeyServerPreferenceNoModify)];
            }
            self.value = [flagsArray copy];
        } break;
        case PGPSignatureSubpacketTypeFeatures: // NSArray of NSNumber(PGPFeature)
        {
            // 5.2.3.24.  Features
            NSMutableArray *featuresArray = [NSMutableArray array];

            for (NSUInteger i = 0; i < packetBodyData.length; i++) {
                PGPFeature feature = PGPFeatureModificationUnknown;
                [packetBodyData getBytes:&feature range:(NSRange){i, 1}];
                [featuresArray addObject:@(feature)];
            }

            self.value = [featuresArray copy];
        } break;
        default:
            if (self.type & 0x80) {
                PGPLogError(@"Unsupported critical subpacket type %d", self.type);
            } else {
               // PGPLogDebug(@"Unsupported subpacket type %d", self.type);
            }
            break;
    }
}

- (nullable NSData *)export:(NSError *__autoreleasing *)error {
    NSMutableData *data = [NSMutableData data];

    // subpacket type
    PGPSignatureSubpacketType type = self.type;
    [data appendBytes:&type length:1];

    switch (self.type & 0x7F) {
        case PGPSignatureSubpacketTypeSignatureCreationTime: // NSDate
        {
            let date = PGPCast(self.value, NSDate);
            let signatureCreationTimestamp = CFSwapInt32HostToBig((UInt32)[date timeIntervalSince1970]);
            [data appendBytes:&signatureCreationTimestamp length:4];
        } break;
        case PGPSignatureSubpacketTypeSignatureExpirationTime: // NSNumber
        case PGPSignatureSubpacketTypeKeyExpirationTime: {
            let validityPeriod = PGPCast(self.value, NSNumber);
            let validityPeriodInt = CFSwapInt32HostToBig((UInt32)validityPeriod.unsignedIntegerValue);
            [data appendBytes:&validityPeriodInt length:4];
        } break;
        case PGPSignatureSubpacketTypeIssuerKeyID: // PGPKeyID
        {
            let _Nullable keyID = PGPCast(self.value, PGPKeyID);
            [data pgp_appendData:[keyID export:nil]];
        } break;
        case PGPSignatureSubpacketTypeExportableCertification: // NSNumber BOOL
        case PGPSignatureSubpacketTypePrimaryUserID: // NSNumber BOOL
        {
            var boolValue = PGPCast(self.value, NSNumber).boolValue;
            [data appendBytes:&boolValue length:1];
        } break;
        case PGPSignatureSubpacketTypeSignerUserID: // NSString
        case PGPSignatureSubpacketTypePreferredKeyServer: // NSString
        case PGPSignatureSubpacketTypePolicyURI: // NSString
        {
            let stringValue = PGPCast(self.value, NSString);
            let _Nullable stringData = [stringValue dataUsingEncoding:NSUTF8StringEncoding];
            [data pgp_appendData:stringData];
        } break;
        case PGPSignatureSubpacketTypeReasonForRevocation: {
            // 5.2.3.23.  Reason for Revocation
            let revocationCode = PGPCast(self.value, NSNumber);
            UInt8 revocationCodeByte = [revocationCode unsignedCharValue];
            [data appendBytes:&revocationCodeByte length:1];
        } break;
        case PGPSignatureSubpacketTypeKeyFlags: // NSArray of NSNumber PGPSignatureFlags
        {
            // TODO: actually it can be more than one byte (documented)
            //      so I should calculate how many bytes do I need here
            let flagsArray = PGPCast(self.value, NSArray);
            if (!flagsArray) {
                break;
            }
            PGPSignatureFlags flagByte = PGPSignatureFlagUnknown;
            for (NSNumber *flagByteNumber in flagsArray) {
                flagByte = flagByte | ((UInt8)[flagByteNumber unsignedIntValue]);
            }
            [data appendBytes:&flagByte length:sizeof(PGPSignatureFlags)];
        } break;
        case PGPSignatureSubpacketTypePreferredSymetricAlgorithm: // NSArray of NSNumber(PGPSymmetricAlgorithm)
        {
            let algorithmsArray = PGPCast(self.value, NSArray);
            if (!algorithmsArray) {
                break;
            }
            for (NSNumber *val in algorithmsArray) {
                PGPSymmetricAlgorithm symmetricAlgorithm = (UInt8)val.unsignedIntValue;
                [data appendBytes:&symmetricAlgorithm length:sizeof(PGPSymmetricAlgorithm)];
            }
        } break;
        case PGPSignatureSubpacketTypePreferredHashAlgorithm: // NSArray of NSNumber(PGPHashAlgorithm)
        {
            let algorithmsArray = PGPCast(self.value, NSArray);
            if (!algorithmsArray) {
                break;
            }

            for (NSNumber *val in algorithmsArray) {
                PGPHashAlgorithm hashAlgorithm = (UInt8)val.unsignedIntValue;
                [data appendBytes:&hashAlgorithm length:sizeof(PGPHashAlgorithm)];
            }
        } break;
        case PGPSignatureSubpacketTypePreferredCompressionAlgorithm: // NSArray of NSNumber(PGPCompressionAlgorithm)
        {
            let algorithmsArray = PGPCast(self.value, NSArray);
            if (!algorithmsArray) {
                break;
            }
            for (NSNumber *val in algorithmsArray) {
                PGPCompressionAlgorithm hashAlgorithm = (UInt8)val.unsignedIntValue;
                [data appendBytes:&hashAlgorithm length:sizeof(PGPCompressionAlgorithm)];
            }
        } break;
        case PGPSignatureSubpacketTypeKeyServerPreference: // NSArray of NSNumber PGPKeyServerPreferenceFlags
        {
            // TODO: actually it can be more than one byte (documented)
            //      so I should calculate how many bytes do I need here
            PGPKeyServerPreferenceFlags allFlags = PGPKeyServerPreferenceUnknown;
            let flagsArray = PGPCast(self.value, NSArray);
            if (!flagsArray) {
                break;
            }
            for (NSNumber *flagNumber in flagsArray) {
                PGPKeyServerPreferenceFlags flag = (PGPKeyServerPreferenceFlags)flagNumber.unsignedIntValue;
                allFlags = allFlags | flag;
            }
            [data appendBytes:&allFlags length:sizeof(PGPKeyServerPreferenceFlags)];
        } break;
        case PGPSignatureSubpacketTypeFeatures: // NSArray of NSNumber PGPFeature
        {
            // TODO: actually it can be more than one byte (documented)
            //      so I should calculate how many bytes do I need here
            let flagsArray = PGPCast(self.value, NSArray);
            if (!flagsArray) {
                break;
            }
            PGPFeature flagByte = PGPFeatureModificationUnknown;
            for (NSNumber *flagByteNumber in flagsArray) {
                flagByte = flagByte | ((UInt8)[flagByteNumber unsignedIntValue]);
            }
            [data appendBytes:&flagByte length:sizeof(PGPSignatureFlags)];
        } break;
        default:
            if (self.type & 0x80) {
                PGPLogError(@"Unsupported critical subpacket type %d", self.type);
            } else {
               // PGPLogDebug(@"Unsupported subpacket type %d", self.type);
            }
            break;
    }

    // subpacket = length + tag(type) + body
    NSMutableData *subpacketData = [NSMutableData data];
    // the subpacket length (1, 2, or 5 octets),
    NSData *subpacketLengthData = [PGPPacket buildNewFormatLengthDataForData:data];
    [subpacketData appendData:subpacketLengthData]; // data with tag
    [subpacketData appendData:data];

    return [subpacketData copy];
}

+ (PGPSignatureSubpacketHeader *)subpacketHeaderFromData:(NSData *)headerData {
    NSUInteger position = 0;

    const UInt8 *lengthOctets = [headerData subdataWithRange:NSMakeRange(position, MIN((NSUInteger)5, headerData.length))].bytes;
    UInt32 headerLength = 0;
    UInt32 subpacketLength = 0;

    //TODO: Use -[PGPPacket parseNewFormatHeaderPacket:]. headerLength is different size !?
    //      Its format is similar to the "new" format packet header lengths, but cannot have Partial Body Lengths.
    if (lengthOctets[0] < 192) {
        // subpacketLen = 1st_octet;
        subpacketLength = lengthOctets[0];
        headerLength = 1;
    } else if (lengthOctets[0] >= 192 && lengthOctets[0] < 255) {
        // subpacketLen = ((1st_octet - 192) << 8) + (2nd_octet) + 192
        subpacketLength = ((lengthOctets[0] - 192) << 8) + (lengthOctets[1]) + 192;
        headerLength = 2;
    } else if (lengthOctets[0] == 255) {
        // subpacketLen = (2nd_octet << 24) | (3rd_octet << 16) |
        //                (4th_octet << 8)  | 5th_octet
        subpacketLength = (lengthOctets[1] << 24) | (lengthOctets[2] << 16) | (lengthOctets[3] << 8) | lengthOctets[4];
        headerLength = 5;
    }
    position = position + headerLength;

    // TODO: Bit 7 of the subpacket type is the "critical" bit.
    PGPSignatureSubpacketType subpacketType = PGPSignatureSubpacketTypeUnknown;
    [headerData getBytes:&subpacketType range:(NSRange){position, 1}];
    headerLength = headerLength + 1;

    // Note: "The length includes the type octet but not this length"
    // Example: 02 19 01
    // length 0x02 = 2
    // type 0x19   = 25
    // body: 0x01  = 1
    // so... given body length is = 2 but body length is in fact = 1
    // this is because given body length include type octet which is from header namespace, not body really.
    // I'm drunk, or person who defined it this way was drunk.
    subpacketLength = subpacketLength - 1;

    PGPSignatureSubpacketHeader *subpacketHeader = [[PGPSignatureSubpacketHeader alloc] init];
    subpacketHeader.type = subpacketType;
    subpacketHeader.headerLength = headerLength;
    subpacketHeader.bodyLength = subpacketLength;

    return subpacketHeader;
}

@end

NS_ASSUME_NONNULL_END

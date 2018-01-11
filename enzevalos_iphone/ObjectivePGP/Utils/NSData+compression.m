//
//  NSData+zlib.m
//
// rfc1950 (zlib format)

#import "NSData+compression.h"
#import "PGPCompressedPacket.h"
#import "PGPMacros+Private.h"
#import <bzlib.h>
#import <zlib.h>

NS_ASSUME_NONNULL_BEGIN

@implementation NSData (compression)

- (nullable NSData *)zipCompressed:(NSError * __autoreleasing _Nullable *)error {
    return [self zlibCompressed:error compressionType:PGPCompressionZIP];
}

- (nullable NSData *)zlibCompressed:(NSError * __autoreleasing _Nullable *)error {
    return [self zlibCompressed:error compressionType:PGPCompressionZLIB];
}

- (nullable NSData *)zlibCompressed:(NSError * __autoreleasing _Nullable *)error compressionType:(PGPCompressionAlgorithm)compressionType {
    if (self.length == 0) {
        if (error) {
            *error = [NSError errorWithDomain:PGPErrorDomain code:PGPErrorGeneral userInfo:@{ NSLocalizedDescriptionKey: @"Compression failed"}];
        }
        return nil;
    }

    z_stream strm;
    strm.zalloc = Z_NULL;
    strm.zfree = Z_NULL;
    strm.opaque = Z_NULL;
    if (compressionType == PGPCompressionZLIB ? deflateInit(&strm, Z_DEFAULT_COMPRESSION) : deflateInit2(&strm, Z_DEFAULT_COMPRESSION, Z_DEFLATED, -13, 8, Z_DEFAULT_STRATEGY) != Z_OK) {
        if (error) {
            NSString *errorMsg = [NSString stringWithCString:strm.msg encoding:NSASCIIStringEncoding];
            *error = [NSError errorWithDomain:@"ZLIB" code:0 userInfo:@{NSLocalizedDescriptionKey: errorMsg}];
        }
        return nil;
    }

    let compressed = [NSMutableData dataWithLength:deflateBound(&strm, self.length)];
    strm.next_out = compressed.mutableBytes;
    strm.avail_out = (uInt)compressed.length;
    strm.next_in = (void *)self.bytes;
    strm.avail_in = (uInt)self.length;

    int ret = 0;
    do {
        ret = deflate(&strm, Z_FINISH);
        if (ret == Z_STREAM_ERROR) {
            if (error) {
                *error = [NSError errorWithDomain:PGPErrorDomain code:ret userInfo:@{ NSLocalizedDescriptionKey: [NSString stringWithFormat:@"Deflate problem. %@", [NSString stringWithCString:strm.msg ?: "" encoding:NSASCIIStringEncoding]]}];
            }
            return nil;
        }
        // extend buffer
        compressed.length = (NSUInteger)(compressed.length * 1.5f);
        strm.avail_out = (uInt)(compressed.length - strm.total_out);
        strm.next_out = compressed.mutableBytes + strm.total_out;
    } while (ret != Z_STREAM_END);

    compressed.length = strm.total_out;

    if (deflateEnd(&strm) != Z_OK) {
        if (error) {
            *error = [NSError errorWithDomain:PGPErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey: [NSString stringWithCString:strm.msg ?: ""  encoding:NSASCIIStringEncoding]}];
        }
        return nil;
    }

    return compressed;
}

- (nullable NSData *)zipDecompressed:(NSError * __autoreleasing _Nullable *)error {
    return [self zlibDecompressed:error compressionType:PGPCompressionZIP];
}

- (nullable NSData *)zlibDecompressed:(NSError * __autoreleasing _Nullable *)error {
    return [self zlibDecompressed:error compressionType:PGPCompressionZLIB];
}


- (nullable NSData *)zlibDecompressed:(NSError * __autoreleasing _Nullable *)error compressionType:(PGPCompressionAlgorithm)compressionType {
    if (self.length == 0) {
        if (error) {
            *error = [NSError errorWithDomain:PGPErrorDomain code:PGPErrorGeneral userInfo:@{ NSLocalizedDescriptionKey: @"Decompression failed"}];
        }
        return nil;
    }

    z_stream strm;
    strm.zalloc = Z_NULL;
    strm.zfree = Z_NULL;
    strm.opaque = Z_NULL;
    if (Z_OK != (compressionType == PGPCompressionZIP ? inflateInit2(&strm, -15) : inflateInit(&strm))) {
        if (error) {
            NSString *errorMsg = [NSString stringWithCString:strm.msg encoding:NSASCIIStringEncoding];
            *error = [NSError errorWithDomain:PGPErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey: errorMsg}];
        }
        return nil;
    }

    let decompressed = [NSMutableData dataWithLength:(NSUInteger)(self.length * 2.5f)];
    strm.next_out = [decompressed mutableBytes];
    strm.avail_out = (uInt)[decompressed length];
    strm.next_in = (void *)[self bytes];
    strm.avail_in = (uInt)[self length];
    // From the gnupg sources this might be needed - of course not like this, as we need to extend the input buffer length for this
    // if (compressionType == PGPCompressionZIP)
    //{
    //    *(strm.next_in + (uInt)[self length]) = 0xFF;
    //}

    while (inflate(&strm, Z_FINISH) != Z_STREAM_END) {
        // inflate should return Z_STREAM_END on the first call
        decompressed.length = (NSUInteger)(decompressed.length * 1.5f);
        strm.next_out = decompressed.mutableBytes + strm.total_out;
        strm.avail_out = (uInt)(decompressed.length - strm.total_out);
        NSLog(@"total in: %@ out: %@",@(strm.total_in), @(strm.total_out));
    }

    [decompressed setLength:strm.total_out];

    int status = inflateEnd(&strm);
    if (status != Z_OK) {
        if (error) {
            NSString *errorMsg = [NSString stringWithCString:strm.msg ?: ""  encoding:NSASCIIStringEncoding];
            *error = [NSError errorWithDomain:PGPErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey: errorMsg}];
        }
        return nil;
    }

    return decompressed;
}

- (nullable NSData *)bzip2Decompressed:(NSError * __autoreleasing _Nullable *)error {
    int bzret = 0;
    bz_stream stream = {.avail_in = 0x00};
    stream.next_in = (void *)[self bytes];
    stream.avail_in = (uInt)self.length;

    const int buffer_size = 10000;
    NSMutableData *buffer = [NSMutableData dataWithLength:buffer_size];
    stream.next_out = [buffer mutableBytes];
    stream.avail_out = buffer_size;

    bzret = BZ2_bzDecompressInit(&stream, 0, NO);
    if (bzret != BZ_OK) {
        if (error) {
            *error = [NSError errorWithDomain:PGPErrorDomain code:bzret userInfo:@{ NSLocalizedDescriptionKey: NSLocalizedString(@"BZ2_bzDecompressInit failed", nil) }];
        }
        return nil;
    }

    NSMutableData *decompressedData = [NSMutableData data];
    do {
        bzret = BZ2_bzDecompress(&stream);
        if (bzret < BZ_OK) {
            if (error) {
                *error = [NSError errorWithDomain:PGPErrorDomain code:bzret userInfo:@{ NSLocalizedDescriptionKey: NSLocalizedString(@"BZ2_bzDecompress failed", nil) }];
            }
            return nil;
        }

        [decompressedData appendBytes:[buffer bytes] length:(buffer_size - stream.avail_out)];
        stream.next_out = [buffer mutableBytes];
        stream.avail_out = buffer_size;
    } while (bzret != BZ_STREAM_END);

    BZ2_bzDecompressEnd(&stream);
    return decompressedData;
}

- (nullable NSData *)bzip2Compressed:(NSError * __autoreleasing _Nullable *)error {
    int bzret = 0;
    bz_stream stream = {.avail_in = 0x00};
    stream.next_in = (void *)[self bytes];
    stream.avail_in = (uInt)self.length;
    unsigned int compression = 9; // should be a value between 1 and 9 inclusive

    const int buffer_size = 10000;
    NSMutableData *buffer = [NSMutableData dataWithLength:buffer_size];
    stream.next_out = [buffer mutableBytes];
    stream.avail_out = buffer_size;

    bzret = BZ2_bzCompressInit(&stream, compression, 0, 0);
    if (bzret != BZ_OK) {
        if (error) {
            *error = [NSError errorWithDomain:PGPErrorDomain code:bzret userInfo:@{ NSLocalizedDescriptionKey: NSLocalizedString(@"BZ2_bzCompressInit failed", nil) }];
        }
        return nil;
    }

    NSMutableData *compressedData = [NSMutableData data];

    do {
        bzret = BZ2_bzCompress(&stream, (stream.avail_in) ? BZ_RUN : BZ_FINISH);
        if (bzret < BZ_OK) {
            if (error) {
                *error = [NSError errorWithDomain:PGPErrorDomain code:bzret userInfo:@{ NSLocalizedDescriptionKey: NSLocalizedString(@"BZ2_bzCompress failed", nil) }];
            }
            return nil;
        }
        [compressedData appendBytes:[buffer bytes] length:(buffer_size - stream.avail_out)];
        stream.next_out = [buffer mutableBytes];
        stream.avail_out = buffer_size;

    } while (bzret != BZ_STREAM_END);

    BZ2_bzCompressEnd(&stream);
    return compressedData;
}

@end

NS_ASSUME_NONNULL_END

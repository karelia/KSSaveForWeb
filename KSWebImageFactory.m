//
//  KSWebImageFactory.m
//  Sandvox
//
//  Created by Mike Abdullah on 10/01/2012.
//  Copyright (c) 2012 Karelia Software. All rights reserved.
//

#import "KSWebImageFactory.h"

@implementation KSWebImageFactory

@synthesize type = _type;
@synthesize lossyCompressionQuality = _compression;

@synthesize context = _context;
- (CIContext *)context;
{
    if (_context)
    {
        
    }
    
    return _context;
}

- (CGImageDestinationRef)createDestinationWithMutableData:(NSMutableData *)data;
{
    CGImageDestinationRef result = CGImageDestinationCreateWithData((CFMutableDataRef)data,
                                                                    (CFStringRef)[self type],
                                                                    1,
                                                                    NULL);
    return result;
}

- (NSData *)finalizeAndReleaseDestination:(CGImageDestinationRef)destination mutableData:(NSMutableData *)data;
{
    if (destination)
    {
        if (CGImageDestinationFinalize(destination))
        {
            return data;
        }
    }
    
    return nil;
}

- (NSData *)dataWithCIImage:(CIImage *)image;
{
    CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceSRGB);
    
    CIContext *context = [self context];
    if (!context)
    {
        context = [CIContext contextWithCGContext:nil
                                          options:[NSDictionary dictionaryWithObjectsAndKeys:
                                                   NSBOOL(YES), kCIContextUseSoftwareRenderer,
                                                   colorSpace, kCIContextOutputColorSpace,
                                                   colorSpace, kCIContextWorkingColorSpace,
                                                   nil]];
    }
    
    CGImageRef cgImage = [context createCGImage:image
                                       fromRect:[image extent]
                                         format:kCIFormatARGB8
                                     colorSpace:colorSpace];
    
    CFRelease(colorSpace);
    
    if (cgImage)
    {
        NSData *result = [self dataWithCGImage:cgImage];
        CFRelease(cgImage);
        return result;
    }
    else
    {
        return nil;
    }
}

- (NSData *)dataWithCGImage:(CGImageRef)image;
{
    NSParameterAssert(image);
    
    NSMutableData *result = [NSMutableData data];
    CGImageDestinationRef destination = [self createDestinationWithMutableData:result];
    
    if (destination)
    {
        CGImageDestinationAddImage(destination,
                                   image,
                                   (CFDictionaryRef)[NSDictionary dictionaryWithObjectsAndKeys:
                                                     [self lossyCompressionQuality], kCGImageDestinationLossyCompressionQuality,
                                                     nil]);
    }
    
    return [self finalizeAndReleaseDestination:destination mutableData:result];
}

- (NSData *)dataWithImageAtIndex:(NSUInteger)index fromSource:(CGImageSourceRef)source
{
    NSMutableData *result = [NSMutableData data];
    CGImageDestinationRef destination = [self createDestinationWithMutableData:result];
    
    if (destination)
    {
        CGImageDestinationAddImageFromSource(destination, source, index, NULL);
    }
    
    return [self finalizeAndReleaseDestination:destination mutableData:result];
}

@end

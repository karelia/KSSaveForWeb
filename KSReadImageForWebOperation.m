//
//  KSReadImageForWebOperation.m
//  Sandvox
//
//  Created by Mike on 13/08/2011.
//  Copyright 2011 Karelia Software. All rights reserved.
//

#import "KSReadImageForWebOperation.h"
#import "KSWriteImageDataOperation.h"

#import <QuartzCore/CoreImage.h>


@implementation KSReadImageForWebOperation

- (id)initWithData:(NSData *)data width:(NSNumber *)width height:(NSNumber *)height;
{
    NSParameterAssert(data);
    if (width) NSParameterAssert(height);
    if (height) NSParameterAssert(width);
    
    if (self = [self init])
    {
        _data = [data copy];
        _width = [width copy];
        _height = [height copy];
    }
    return self;
}

- (void)dealloc
{
    [_data release];
    [_width release];
    [_height release];
    if (_source) CFRelease(_source);
    if (_properties) CFRelease(_properties);
    CGImageRelease(_image);
    
    [super dealloc];
}

@synthesize imageSource = _source;
@synthesize CGImage = _image;

- (CFDictionaryRef)imageProperties;
{
    if (!_properties && _source) _properties = CGImageSourceCopyPropertiesAtIndex(_source, 0, NULL);
    return _properties;
}

- (void)main
{
    _source = CGImageSourceCreateWithData((CFDataRef)_data, NULL);
    [_data release]; _data = nil;
    if (!_source) return;
    
    
    // Is the colorspace suitable?
    CFDictionaryRef properties = [self imageProperties];
    if (properties)
    {
        NSString *colorSpaceName = (NSString *)CFDictionaryGetValue(properties, kCGImagePropertyProfileName);
        if ([colorSpaceName isEqualToString:@"sRGB IEC61966-2.1"])
        {
            // If no scaling required, no need to read out CGImage
            if (![self needsSizing]) return;
        }
    }
    
    _image = CGImageSourceCreateImageAtIndex(_source, 0, NULL);
}

- (BOOL)needsSizing;    // NO if image is already correct dimensions
{
    CFDictionaryRef properties = [self imageProperties];
    if (properties)
    {
        if (!_width && !_height) return NO;
        
        if ([(NSNumber *)CFDictionaryGetValue(properties, kCGImagePropertyPixelWidth) isEqualToNumber:_width] &&
            [(NSNumber *)CFDictionaryGetValue(properties, kCGImagePropertyPixelHeight) isEqualToNumber:_height])
        {                
            // Image is the right size already
            return NO;
        }
    }
    
    return YES;
}

- (NSData *)dataWithType:(NSString *)type
             scalingMode:(KSImageScalingMode)scalingMode
              sharpening:(CGFloat)sharpeningFactor          // only applied when scaling
                 context:(CIContext *)context;
{
    // Can just copy the image data straight across?
    CGImageRef cgImage = [self CGImage];
    if (!cgImage)
    {
        if (![self isFinished]) return nil; // -CGImage should return nil if not finished
        
        
        NSMutableData *result = [NSMutableData data];
        
        CGImageDestinationRef destination = CGImageDestinationCreateWithData((CFMutableDataRef)result,
                                                                             (CFStringRef)type,
                                                                             1,
                                                                             NULL);
        OBASSERT(destination);
        
        // As far as I can tell, this avoids recompressing JPEGs
        CGImageDestinationAddImageFromSource(destination, _source, 0, NULL);
        
        if (!CGImageDestinationFinalize(destination)) result = nil;
        CFRelease(destination);
        
        return result;
    }
    
    
    
    
    
    // Render a CGImage
    CIImage *image = [self newCIImageWithScalingMode:scalingMode sharpening:sharpeningFactor];
    
    KSCreateCGImageForWebOperation *op = [[KSCreateCGImageForWebOperation alloc] initWithCIImage:image
                                                                                         context:context];
    
    [image release];
    [op start]; // it's not concurrent
    
    
    // Convert to data
    KSWriteImageDataOperation *dataOp = [[KSWriteImageDataOperation alloc] initWithCGImageOperation:op
                                                                                               type:type];
    [op release];
    
    [dataOp start]; // it's not concurrent
    NSData *result = [[[dataOp data] retain] autorelease];
    [dataOp release];
    
    return result;
}

- (CIImage *)newCIImageWithScalingMode:(KSImageScalingMode)scalingMode
                            sharpening:(CGFloat)sharpeningFactor;
{
    // Scale the image if needed
    CIImage *result = [[CIImage alloc] initWithCGImage:[self CGImage]];
    if ([self needsSizing])
    {
        CIImage *scaledImage = [result imageByScalingToSize:CGSizeMake([_width floatValue], [_height floatValue])
                                                       mode:scalingMode
                                                opaqueEdges:YES];
        OBASSERT(scaledImage);
        
        
        // Sharpen if needed
        if (sharpeningFactor > 0)
        {
            scaledImage = [scaledImage sharpenLuminanceWithFactor:sharpeningFactor];
        }
        OBASSERT(scaledImage);
        
        [scaledImage retain];
        [result release]; result = scaledImage;
    }
    
    return result;
}

@end
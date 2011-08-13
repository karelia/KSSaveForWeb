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


#define RESULT_PROLOGUE if ([self isCancelled]) [NSException raise:NSInvocationOperationCancelledException format:@"Cancelled"];


@implementation KSReadImageForWebOperation

#pragma mark Lifecycle

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

#pragma mark Properties

- (BOOL)isAcceptableForWeb;
{
    // Is the colorspace suitable?
    CFDictionaryRef properties = [self imageProperties];
    if (properties)
    {
        NSString *colorSpaceName = (NSString *)CFDictionaryGetValue(properties, kCGImagePropertyProfileName);
        if ([colorSpaceName isEqualToString:@"sRGB IEC61966-2.1"])
        {
            // If no scaling required, no need to read out CGImage
            return YES;
        }
    }
    
    return NO;
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

- (CGImageSourceRef)imageSource;
{
    RESULT_PROLOGUE
    
    if (![self isFinished]) return NULL;
    return _source;
}

- (CGImageRef)CGImage;
{
    RESULT_PROLOGUE;
    
    if (_image || ![self isFinished] || !_source)
    {
        return _image;
    }
    
    CGImageRef result = CGImageSourceCreateImageAtIndex(_source, 0, NULL);
    [(id <NSObject>)result autorelease];
    return result;
}

- (CFDictionaryRef)imageProperties;
{
    RESULT_PROLOGUE
    
    if (!_properties && _source) _properties = CGImageSourceCopyPropertiesAtIndex(_source, 0, NULL);
    return _properties;
}

- (void)main
{
    _source = CGImageSourceCreateWithData((CFDataRef)_data, NULL);
    [_data release]; _data = nil;
    if (!_source) return;
    
    
    // If no colorsapce OK and no scaling required, no need to read out CGImage
    if ([self isAcceptableForWeb] && ![self needsSizing]) return;
    
    _image = CGImageSourceCreateImageAtIndex(_source, 0, NULL);
}

- (NSData *)dataWithType:(NSString *)type
             scalingMode:(KSImageScalingMode)scalingMode
              sharpening:(CGFloat)sharpeningFactor          // only applied when scaling
                 context:(CIContext *)context;
{
    RESULT_PROLOGUE;
    if (![self isFinished]) return nil;
    
    
    // Can just copy the image data straight across?
    // FIXME: This could use Core Image unecessarily if somebody already called -CGImage
    if (!_image)
    {        
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
    KSCreateCGImageForWebOperation *op = [[KSCreateCGImageForWebOperation alloc] initWithReadOperation:self
                                                                                           scalingMode:scalingMode
                                                                                            sharpening:sharpeningFactor
                                                                                               context:context];
    
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
    CGImageRef image = [self CGImage];
    if (!image) return nil;
    
    CIImage *result = [[CIImage alloc] initWithCGImage:image];
    
    // Scale the image if needed
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

//
//  KSWriteImageDataOperation.m
//  Sandvox
//
//  Created by Mike on 13/08/2011.
//  Copyright 2011 Karelia Software. All rights reserved.
//

#import "KSWriteImageDataOperation.h"

#import <QuartzCore/QuartzCore.h>


@implementation KSWriteImageDataOperation

#pragma mark Lifecycle

- (id)initWithCIImage:(CIImage *)image
                 type:(NSString *)type
              context:(CIContext *)context;
{
    NSParameterAssert(image);
    NSParameterAssert(type);
    
    if (self = [self init])
    {
        _ciImage = [image copy];
        _context = [context retain];
        _type = [type copy];
    }
    
    return self;
}

- (id)initWithCGImage:(CGImageRef)image type:(NSString *)type
{
    NSParameterAssert(image);
    NSParameterAssert(type);
    
    if (self = [self init])
    {
        _cgImage = image;   CFRetain(_cgImage);
        _type = [type copy];
    }
    
    return self;
}

- (void)dealloc;
{
    [_ciImage release];
    [_context release];
    CGImageRelease(_cgImage);
    [_type release];
    [_result release];
    
    [super dealloc];
}

#pragma mark Properties

@synthesize data = _result;
@synthesize type = _type;
@synthesize CIImage = _ciImage;

- (CGImageRef)CGImage;
{
    if (!_cgImage)
    {
        CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceSRGB);
        
        CIContext *context = _context;
        if (!context)
        {
            context = [CIContext contextWithCGContext:nil
                                              options:[NSDictionary dictionaryWithObjectsAndKeys:
                                                       NSBOOL(YES), kCIContextUseSoftwareRenderer,
                                                       colorSpace, kCIContextOutputColorSpace,
                                                       colorSpace, kCIContextWorkingColorSpace,
                                                       nil]];
        }
        
        _cgImage = [context createCGImage:_ciImage
                                 fromRect:[_ciImage extent]
                                   format:kCIFormatARGB8
                               colorSpace:colorSpace];
        
        CFRelease(colorSpace);
    }
    
    return _cgImage;
}

#pragma mark Work

- (void)main
{
    // Prepare the destination
    NSMutableData *result = [[NSMutableData alloc] init];
    
    CGImageDestinationRef destination = CGImageDestinationCreateWithData((CFMutableDataRef)result,
                                                                         (CFStringRef)_type,
                                                                         1,
                                                                         NULL);
    if (!destination)
    {
        [result release];
        return;
    }
    
    
    // Find the image to write. Potentially a long task on Snowy or earlier I've found, since the image is not rendered lazily
    CGImageRef image = [self CGImage];
    if ([self isCancelled])
    {
        [result release];
        CFRelease(destination);
        return;
    }
    
    if (image)
    {
        [[self class] addCGImage:image toDestination:destination];
    }
    else
    {
        NSOperation *readOp = nil;//[_createImageOp readOperation];
        CGImageSourceRef source = [readOp imageSource];
        
        if (source && ![readOp needsSizing] && [readOp isAcceptableForWeb])
        {
            // Copy the image from source to destination!
            [[self class] addImageToDestination:destination fromSource:source];
        }
        else
        {
            [result release];
            CFRelease(destination);
            return;
        }
    }
    
    
    BOOL wrote = CGImageDestinationFinalize(destination);
    CFRelease(destination);
    
    if (wrote)
    {
        _result = result;
    }
    else
    {
        [result release];
    }
}

+ (void)addCIImage:(CIImage *)image toDestination:(CGImageDestinationRef)destination context:(CIContext *)context;
{
    
}

+ (void)addCGImage:(CGImageRef)image toDestination:(CGImageDestinationRef)destination;
{
    
}

+ (NSData *)dataWithImageFromSource:(CGImageSourceRef)source type:(NSString *)type;
{
    NSMutableData *result = [NSMutableData data];
    
    CGImageDestinationRef destination = CGImageDestinationCreateWithData((CFMutableDataRef)result,
                                                                         (CFStringRef)type,
                                                                         1,
                                                                         NULL);
    
    if (destination)
    {
        [self addImageToDestination:destination fromSource:source];
        CFRelease(destination);
        
        return result;
    }
    else
    {
        return nil;
    }
}

+ (void)addImageToDestination:(CGImageDestinationRef)destination fromSource:(CGImageSourceRef)source;
{
    // TODO: strip the image of all properties
    CGImageDestinationAddImageFromSource(destination, source, 0, NULL);
}

@end

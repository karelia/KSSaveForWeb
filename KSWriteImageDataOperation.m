//
//  KSWriteImageDataOperation.m
//  Sandvox
//
//  Created by Mike on 13/08/2011.
//  Copyright 2011 Karelia Software. All rights reserved.
//

#import "KSWriteImageDataOperation.h"


@implementation KSWriteImageDataOperation

#pragma mark Lifecycle

- (id)initWithData:(NSData *)data
              type:(NSString *)type
             width:(NSNumber *)width
            height:(NSNumber *)height
             queue:(NSOperationQueue *)readingQueue
       scalingMode:(KSImageScalingMode)scalingMode
        sharpening:(CGFloat)sharpeningFactor  // only applied if scaling needed
           context:(CIContext *)context
             queue:(NSOperationQueue *)coreImageQueue;
{
    NSParameterAssert(readingQueue);
    NSParameterAssert(coreImageQueue);
    
    KSReadImageForWebOperation *readOp = [[KSReadImageForWebOperation alloc] initWithData:data
                                                                                    width:width
                                                                                   height:height];
    
    [readingQueue addOperation:readOp];
    
    KSCreateCGImageForWebOperation *createOp = [[KSCreateCGImageForWebOperation alloc] initWithReadOperation:readOp
                                                                                                 scalingMode:scalingMode
                                                                                                  sharpening:sharpeningFactor
                                                                                                     context:context];
    [readOp release];
    
    [coreImageQueue addOperation:createOp];
    
    self = [self initWithCGImageOperation:createOp type:type];
    
    [createOp release];
    return self;
}

- (id)initWithCIImage:(CIImage *)image
                 type:(NSString *)type
              context:(CIContext *)context
                queue:(NSOperationQueue *)coreImageQueue;
{
    NSParameterAssert(coreImageQueue);
    
    KSCreateCGImageForWebOperation *imageOp = [[KSCreateCGImageForWebOperation alloc] initWithCIImage:image
                                                                                              context:context];
    
    [coreImageQueue addOperation:imageOp];
    
    return [self initWithCGImageOperation:imageOp type:type];
}

- (id)initWithCGImageOperation:(KSCreateCGImageForWebOperation *)imageOp type:(NSString *)type;
{
    NSParameterAssert(imageOp);
    NSParameterAssert(type);
    
    if (self = [self init])
    {
        _createImageOp = [imageOp retain];
        _type = [type copy];
        
        [self addDependency:imageOp];
    }
    
    return self;
}

- (void)dealloc;
{
    [_type release];
    [_createImageOp release];
    [_result release];
    
    [super dealloc];
}

#pragma mark Properties

@synthesize data = _result;

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
    
    
    // Find the image to write
    CGImageRef image = [_createImageOp CGImage];
    if (image)
    {
        CGImageDestinationAddImage(destination,
                                   image,
                                   (CFDictionaryRef)[NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:0.7] forKey:(NSString *)kCGImageDestinationLossyCompressionQuality]);
    }
    else
    {
        KSReadImageForWebOperation *readOp = [_createImageOp readOperation];
        CGImageSourceRef source = [readOp imageSource];
        
        if (source && ![readOp needsSizing] && [readOp isAcceptableForWeb])
        {
            // Copy the image from source to destination!
            CGImageDestinationAddImageFromSource(destination, source, 0, NULL);
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

@end

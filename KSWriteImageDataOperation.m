//
//  KSWriteImageDataOperation.m
//  Sandvox
//
//  Created by Mike on 13/08/2011.
//  Copyright 2011 Karelia Software. All rights reserved.
//

#import "KSWriteImageDataOperation.h"


@implementation KSWriteImageDataOperation

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
        _imageOp = [imageOp retain];
        _type = [type copy];
        
        [self addDependency:imageOp];
    }
    
    return self;
}

- (void)dealloc;
{
    [_type release];
    [_imageOp release];
    [_result release];
    
    [super dealloc];
}

@synthesize data = _result;

- (void)main
{
    CGImageRef image = [_imageOp CGImage];
    if (!image) return;
    
    NSMutableData *result = [[NSMutableData alloc] init];
    
    CGImageDestinationRef destination = CGImageDestinationCreateWithData((CFMutableDataRef)result,
                                                                         (CFStringRef)_type,
                                                                         1,
                                                                         NULL);
    
    CGImageDestinationAddImage(destination,
                               image,
                               (CFDictionaryRef)[NSDictionary dictionaryWithObject:[NSNumber numberWithFloat:0.7] forKey:(NSString *)kCGImageDestinationLossyCompressionQuality]);
    
    CGImageDestinationFinalize(destination);
    CFRelease(destination);
    _result = result;
}

@end

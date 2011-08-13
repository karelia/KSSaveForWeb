//
//  KSCreateCGImageForWebOperation.m
//  Sandvox
//
//  Created by Mike on 12/08/2011.
//  Copyright 2011 Karelia Software. All rights reserved.
//

#import "KSCreateCGImageForWebOperation.h"

#import <QuartzCore/CoreImage.h>


@implementation KSCreateCGImageForWebOperation

#pragma mark Lifecycle

- (id)initWithCIImage:(CIImage *)image context:(CIContext *)context;
{
    NSParameterAssert(image);
    
    if (self = [self init])
    {
        _image = [image retain];
        _context = [context retain];
    }
    return self;
}

- (id)initWithReadOperation:(KSReadImageForWebOperation *)readOp
                scalingMode:(KSImageScalingMode)scalingMode
                 sharpening:(CGFloat)sharpeningFactor
                    context:(CIContext *)context;
{
    NSParameterAssert(readOp);
    
    if (self = [self init])
    {
        _readOp = [readOp retain];
        _scalingMode = scalingMode;
        _sharpening = sharpeningFactor;
        _context = [context retain];
        
        [self addDependency:readOp];
    }
    
    return self;
}

- (void)dealloc;
{
    [_image release];
    [_readOp release];
    [_context release];
    CGImageRelease(_result);
    
    [super dealloc];
}

@synthesize CGImage = _result;
@synthesize readOperation = _readOp;

- (void)main
{
    KSReadImageForWebOperation *readOp = [self readOperation];
    if (readOp)
    {
        if (![readOp needsSizing] && [readOp isAcceptableForWeb])
        {
            return;
        }
        
        _image = [readOp newCIImageWithScalingMode:_scalingMode sharpening:_sharpening];
        if (!_image) return;
    }
    
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateWithName(kCGColorSpaceSRGB);
    
    if (!_context)
    {
        _context = [CIContext contextWithCGContext:nil
                                           options:[NSDictionary dictionaryWithObjectsAndKeys:
                                                    NSBOOL(YES), kCIContextUseSoftwareRenderer,
                                                    colorSpace, kCIContextOutputColorSpace,
                                                    colorSpace, kCIContextWorkingColorSpace,
                                                    nil]];
        [_context retain];
    }
    
    _result = [_context createCGImage:_image
                             fromRect:[_image extent]
                               format:kCIFormatARGB8
                           colorSpace:colorSpace];
    
    CFRelease(colorSpace);
}

@end

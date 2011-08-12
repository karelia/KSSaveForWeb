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

- (void)dealloc;
{
    [_image release];
    [_context release];
    CGImageRelease(_result);
    
    [super dealloc];
}

@synthesize CGImage = _result;

- (void)main
{
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

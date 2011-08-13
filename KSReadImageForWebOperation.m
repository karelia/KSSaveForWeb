//
//  KSReadImageForWebOperation.m
//  Sandvox
//
//  Created by Mike on 13/08/2011.
//  Copyright 2011 Karelia Software. All rights reserved.
//

#import "KSReadImageForWebOperation.h"


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
            if (!_width && !_height) return;
            
            if ([(NSNumber *)CFDictionaryGetValue(properties, kCGImagePropertyPixelWidth) isEqualToNumber:_width] &&
                [(NSNumber *)CFDictionaryGetValue(properties, kCGImagePropertyPixelHeight) isEqualToNumber:_height])
            {                
                // Image is the right size already
                return;
            }
        }
    }
    
    _image = CGImageSourceCreateImageAtIndex(_source, 0, NULL);
}

@end

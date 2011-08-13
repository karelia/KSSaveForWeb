//
//  KSReadImageForWebOperation.h
//  Sandvox
//
//  Created by Mike on 13/08/2011.
//  Copyright 2011 Karelia Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "CIImage+Karelia.h"


@interface KSReadImageForWebOperation : NSOperation
{
  @private
    NSData              *_data;
    NSNumber            *_width;
    NSNumber            *_height;
    CGImageSourceRef    _source;
    CFDictionaryRef     _properties;
    CGImageRef          _image;
}

// Pass in an image's data for reading
// The operation will create a CGImageSource object for reading the data. You can access it once finished from -imageSource
// If you have a target image size, pass in as the width and height paramaters
// If the operation determines the image needs scaling, or is in an unsuitable colorspace for the web, -CGImage will be populated once finished

- (id)initWithData:(NSData *)data
             width:(NSNumber *)width
            height:(NSNumber *)height;

- (BOOL)isAcceptableForWeb; // YES if the source image isn't in a problem colorspace
- (BOOL)needsSizing;    // NO if image is already correct dimensions

@property(readonly) CGImageSourceRef imageSource;   // behaves like -[NSInvocationOperation result]
@property(readonly) CFDictionaryRef imageProperties;    // nil if couldn't be read

// If the operation has cached a CGImage, returns it. Otherwise blocks while the image is created from source
@property(readonly) CGImageRef CGImage;

// Blocks while writing the image data, so in general it's better to do this using a KSWriteImageDataOperation
- (NSData *)dataWithType:(NSString *)type
             scalingMode:(KSImageScalingMode)scalingMode
              sharpening:(CGFloat)sharpeningFactor          // only applied when scaling
                 context:(CIContext *)context;

// Creates a CIImage from -CGImage with appropriate scaling applied
- (CIImage *)newCIImageWithScalingMode:(KSImageScalingMode)scalingMode
                            sharpening:(CGFloat)sharpeningFactor;

@end

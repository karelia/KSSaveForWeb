//
//  KSReadImageForWebOperation.h
//  Sandvox
//
//  Created by Mike on 13/08/2011.
//  Copyright 2011 Karelia Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>


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

- (id)initWithData:(NSData *)data width:(NSNumber *)width height:(NSNumber *)height;

@property(readonly) CGImageSourceRef imageSource;
@property(readonly) CFDictionaryRef imageProperties;    // nil if couldn't be read
@property(readonly) CGImageRef CGImage;

@end

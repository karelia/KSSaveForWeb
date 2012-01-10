//
//  KSWriteImageDataOperation.h
//  Sandvox
//
//  Created by Mike on 13/08/2011.
//  Copyright 2011 Karelia Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface KSWriteImageDataOperation : NSOperation
{
  @private
    CIImage     *_ciImage;
    CIContext   *_context;
    CGImageRef  _cgImage;
    NSString    *_type;
    NSData      *_result;
}

// Convenient way to get data from a CIImage. Your app provides a context for doing the Core Image work on. You then schedule the receiver on a  queue, suitable for writing the image (generally a serial queue so the context can't be accessed from multiple threads at once)
// If context is nil, operation will create its own. It's best if you can pass one in since contexts cache their resources
// Remember if providing your own context, they are only safe to be used from a single thread at a time, so make sure you don't run multiple operations at once if they share a context
// In general set context up to use sRGB colorspace, the .m file shows how to do that
- (id)initWithCIImage:(CIImage *)image
                 type:(NSString *)type
              context:(CIContext *)context;

- (id)initWithCGImage:(CGImageRef)image type:(NSString *)type;

@property(nonatomic, readonly) NSData *data;
@property(nonatomic, copy, readonly) NSString *type;
@property(nonatomic, copy, readonly) CIImage *CIImage;    // nil if one wasn't supplied
@property(nonatomic, readonly) CGImageRef CGImage;  // NOT safe to call while operation is running


#pragma mark Components

/*  For images already in the correct format, nil compression will avoid recompressing. But I have no idea quite what happens if the
 */

+ (void)addCIImage:(CIImage *)image
     toDestination:(CGImageDestinationRef)destination
 compressionFactor:(NSNumber *)compression
           context:(CIContext *)context;

+ (void)addCGImage:(CGImageRef)image
     toDestination:(CGImageDestinationRef)destination
 compressionFactor:(NSNumber *)compression;

// If a source image is already the correct size and colorspace, these methods are able to shortcut Core Image etc. and copy the image directly from source to destination. The type can be changed enroute, and compression can be applied (don't have API for the latter yet)
+ (NSData *)dataWithImageFromSource:(CGImageSourceRef)source type:(NSString *)type;
+ (void)addImageToDestination:(CGImageDestinationRef)destination fromSource:(CGImageSourceRef)source;

@end

//
//  KSWebImageFactory.h
//  Sandvox
//
//  Created by Mike Abdullah on 10/01/2012.
//  Copyright (c) 2012 Karelia Software. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>


@interface KSWebImageFactory : NSObject
{
  @private
    NSString    *_type;
    NSNumber    *_compression;
    CIContext   *_context;
}

@property(nonatomic, copy) NSString *type;
@property(nonatomic, copy) NSNumber *lossyCompressionQuality;
@property(nonatomic, retain) CIContext *context;    // if not supplied, factory will create its own

- (NSData *)dataWithCIImage:(CIImage *)image;
- (NSData *)dataWithCGImage:(CGImageRef)image;
- (NSData *)dataWithImageAtIndex:(NSUInteger)index fromSource:(CGImageSourceRef)source;

@end

//
//  KSCreateCGImageForWebOperation.h
//  Sandvox
//
//  Created by Mike on 12/08/2011.
//  Copyright 2011 Karelia Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface KSCreateCGImageForWebOperation : NSOperation
{
  @private
    CIImage     *_image;
    CIContext   *_context;
    CGImageRef  _result;
}

// If context is nil, operation will create its own. It's best if you can pass one in since contexts cache their resources. If you do, I'm fairly sure contexts are only safe to be used from a single thread at a time, so make sure you place all such operations on the same queue. It is assumed the context has been set up in sRGB colorspace
- (id)initWithCIImage:(CIImage *)image context:(CIContext *)context;

@property(nonatomic, readonly) CGImageRef CGImage;  // NOT KVO-compliant, observe isFinished instead

@end

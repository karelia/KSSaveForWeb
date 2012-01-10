//
//  KSCreateCGImageForWebOperation.h
//  Sandvox
//
//  Created by Mike on 12/08/2011.
//  Copyright 2011 Karelia Software. All rights reserved.
//


#import "KSReadImageForWebOperation.h"


@interface KSCreateCGImageForWebOperation : NSOperation
{
  @private
    CIImage     *_image;
    CIContext   *_context;
    CGImageRef  _result;
    
    KSReadImageForWebOperation  *_readOp;
    KSImageScalingMode          _scalingMode;
    CGFloat                     _sharpening;
}

// If context is nil, operation will create its own. It's best if you can pass one in since contexts cache their resources
// If providing your own context, I'm fairly sure they are only safe to be used from a single thread at a time, so make sure you place all such operations on the same queue. In general set context up to use sRGB colorspace, the .m file shows how to do that
- (id)initWithCIImage:(CIImage *)image context:(CIContext *)context;

// Once readOp completes, scales/adjusts colorspace if needed
- (id)initWithReadOperation:(KSReadImageForWebOperation *)readOp
                scalingMode:(KSImageScalingMode)scalingMode
                 sharpening:(CGFloat)sharpeningFactor
                    context:(CIContext *)context;

// Just to infuriate you, this image produced is NOT threadsafe. Instead it renders lazily when used (I'm not sure if it's then cached after that)
// NOT KVO-compliant, observe isFinished instead
@property(nonatomic, readonly) CGImageRef CGImage;

@property(nonatomic, retain, readonly) KSReadImageForWebOperation *readOperation;

@end

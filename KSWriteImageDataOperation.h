//
//  KSWriteImageDataOperation.h
//  Sandvox
//
//  Created by Mike on 13/08/2011.
//  Copyright 2011 Karelia Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "KSCreateCGImageForWebOperation.h"


@interface KSWriteImageDataOperation : NSOperation
{
  @private
    NSString                        *_type;
    KSCreateCGImageForWebOperation  *_createImageOp;
    NSData                          *_result;
}

// Convenient way to get data from a CIImage. Your app provides a queue and context for doing the Core Image work on (in general a serial queue since Core Image is internally multithreaded)
// You then schedule the receiver on a different queue, suitable for writing the image
- (id)initWithCIImage:(CIImage *)image
                 type:(NSString *)type
              context:(CIContext *)context
                queue:(NSOperationQueue *)coreImageQueue;

- (id)initWithCGImageOperation:(KSCreateCGImageForWebOperation *)imageOp type:(NSString *)type;

@property(nonatomic, readonly) NSData *data;
@property(nonatomic, readonly) NSString *type;

@end

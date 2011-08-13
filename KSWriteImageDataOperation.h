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
    KSCreateCGImageForWebOperation  *_imageOp;
    NSData                          *_result;
}

- (id)initWithCGImageOperation:(KSCreateCGImageForWebOperation *)imageOp type:(NSString *)type;

@property(nonatomic, readonly) NSData *data;

@end

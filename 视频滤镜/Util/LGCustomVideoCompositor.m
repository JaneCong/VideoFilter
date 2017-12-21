//
//  LGCustomVideoCompositor.m
//  VideoBlend
//
//  Created by L了个G on 2017/12/20.
//  Copyright © 2017年 L了个G. All rights reserved.
//

#import "LGCustomVideoCompositor.h"
#import "LGCustomVideoCompositionInstruction.h"
#import "LGRender.h"
@interface LGCustomVideoCompositor()
{
    BOOL                                _shouldCancelAllRequests;
    BOOL                                _renderContextDidChange;
    dispatch_queue_t                    _renderingQueue;
    dispatch_queue_t                    _renderContextQueue;
    AVVideoCompositionRenderContext*    _renderContext;
}
@end

@implementation LGCustomVideoCompositor
- (id)init
{
    self = [super init];
    if (self)
    {
        _renderingQueue = dispatch_queue_create("com.netease.maker.renderingqueue", DISPATCH_QUEUE_SERIAL);
        _renderContextQueue = dispatch_queue_create("com.netease.maker.rendercontextqueue", DISPATCH_QUEUE_SERIAL);
        _renderContextDidChange = NO;
        //        _transitionRender = [[MMCustomTransitionRender alloc] init];
        //        _filterRender = [[MMCustomFilterRender alloc] init];
        //        _normalRender = [[MMCustomVideoNormalRender alloc] init];
        
    }
    return self;
}
- (NSDictionary *)sourcePixelBufferAttributes
{
    return @{ (NSString *)kCVPixelBufferPixelFormatTypeKey : [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA],
              (NSString*)kCVPixelBufferOpenGLESCompatibilityKey : [NSNumber numberWithBool:YES]};
}

- (NSDictionary *)requiredPixelBufferAttributesForRenderContext
{
    return @{ (NSString *)kCVPixelBufferPixelFormatTypeKey : [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA],
              (NSString*)kCVPixelBufferOpenGLESCompatibilityKey : [NSNumber numberWithBool:YES]};
}

- (void)renderContextChanged:(AVVideoCompositionRenderContext *)newRenderContext
{
    NSLog(@"change %@",newRenderContext);
    dispatch_sync(_renderContextQueue, ^() {
        _renderContext = newRenderContext;
        _renderContextDidChange = YES;
    });
}

- (void)startVideoCompositionRequest:(AVAsynchronousVideoCompositionRequest *)request
{
    @autoreleasepool {
        dispatch_async(_renderingQueue,^() {
            
            if (_shouldCancelAllRequests) {
                [request finishCancelledRequest];
            } else {
                NSError *err = nil;
                
                CVPixelBufferRef resultPixels = [self newRenderedPixelBufferForRequest:request error:&err];
                
                if (resultPixels) {
                    [request finishWithComposedVideoFrame:resultPixels];
                    CFRelease(resultPixels);
                } else {
                    [request finishWithError:err];
                }
            }
        });
    }
}


- (CVPixelBufferRef)newRenderedPixelBufferForRequest:(AVAsynchronousVideoCompositionRequest *)request error:(NSError **)errOut
{
    CVPixelBufferRef dstPixels = nil;
    
    LGCustomVideoCompositionInstruction *currentInstruction = (LGCustomVideoCompositionInstruction *)request.videoCompositionInstruction;
    CVPixelBufferRef foregroundSourceBuffer = [request sourceFrameByTrackID:currentInstruction.sourceTrackID];
    
    
    dstPixels = [_renderContext newPixelBuffer];
    
    [[LGRender sharedRender] renderPixelBuffer:dstPixels usingSourceBuffer:foregroundSourceBuffer type:currentInstruction.filterType];

    if (!dstPixels) {
        NSLog(@"disPixels is nil");
    }
    return dstPixels;
}
- (void)cancelAllPendingVideoCompositionRequests
{
    _shouldCancelAllRequests = YES;
    
    dispatch_barrier_async(_renderingQueue, ^() {
        
        _shouldCancelAllRequests = NO;
    });
}

@end

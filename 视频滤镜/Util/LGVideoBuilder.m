//
//  LGVideoBuilder.m
//  VideoBlend
//
//  Created by L了个G on 2017/12/20.
//  Copyright © 2017年 L了个G. All rights reserved.
//

#import "LGVideoBuilder.h"
#import "LGCustomVideoCompositionInstruction.h"
#import "LGCustomVideoCompositor.h"
@interface LGVideoBuilder()
@property (nonatomic, strong) AVMutableComposition *composition;
@property (nonatomic, strong) AVMutableVideoComposition *videoComposition;
@end
@implementation LGVideoBuilder
+ (instancetype)sharedBuilder {
    static id instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [self new];
    });
    return instance;
}

-(void)buildVideoWithModel:(LGVideoEditModel *)model
{
    self.composition = [AVMutableComposition composition];
    self.videoComposition = [AVMutableVideoComposition videoComposition];
    self.videoComposition.customVideoCompositorClass = [LGCustomVideoCompositor class];
    
    AVAssetTrack *track0 = [[model.asset tracksWithMediaType:AVMediaTypeVideo] firstObject];
    
    AVMutableCompositionTrack *firstTrack = [self.composition addMutableTrackWithMediaType:AVMediaTypeVideo preferredTrackID:kCMPersistentTrackID_Invalid];
    
    [firstTrack insertTimeRange:track0.timeRange ofTrack:track0 atTime:kCMTimeZero error:nil];
    
    
    LGCustomVideoCompositionInstruction *videoInstruction = [[LGCustomVideoCompositionInstruction alloc] initSourceTrackID:firstTrack.trackID forTimeRange:track0.timeRange type:model.filterType];
    
    self.videoComposition.renderSize = track0.naturalSize;
    self.videoComposition.frameDuration = CMTimeMake(1, 15);
    self.videoComposition.instructions = @[videoInstruction];
}



-(AVPlayerItem *)buildPlayerItem
{
    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:self.composition];
    playerItem.videoComposition = self.videoComposition;
    return playerItem;
    
}

@end

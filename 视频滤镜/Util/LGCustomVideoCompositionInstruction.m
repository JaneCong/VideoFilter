//
//  LGCustomVideoCompositionInstruction.m
//  VideoBlend
//
//  Created by L了个G on 2017/12/20.
//  Copyright © 2017年 L了个G. All rights reserved.
//

#import "LGCustomVideoCompositionInstruction.h"

@implementation LGCustomVideoCompositionInstruction
@synthesize timeRange = _timeRange;
@synthesize enablePostProcessing = _enablePostProcessing;
@synthesize containsTweening = _containsTweening;
@synthesize requiredSourceTrackIDs = _requiredSourceTrackIDs;
@synthesize passthroughTrackID = _passthroughTrackID;

-(id)initSourceTrackID:(CMPersistentTrackID)sourceTrackID forTimeRange:(CMTimeRange)timeRange type:(FilterType)type
{
    self = [super init];
    if (self) {
        _passthroughTrackID = kCMPersistentTrackID_Invalid;
        _requiredSourceTrackIDs = @[@(sourceTrackID)];
        _sourceTrackID = sourceTrackID;
        _timeRange = timeRange;
        _containsTweening = YES;
        _enablePostProcessing = YES;
        _filterType = type;
    }
    return self;
}

-(id)initSourceTrackID:(NSArray *)sourceTrackIDs forTimeRange:(CMTimeRange)timeRange
{
    self = [super init];
    if (self) {
        _passthroughTrackID = kCMPersistentTrackID_Invalid;
        _requiredSourceTrackIDs = sourceTrackIDs;
        _timeRange = timeRange;
        _containsTweening = YES;
        _enablePostProcessing = YES;
    }
    return self;
}
@end

//
//  LGCustomVideoCompositionInstruction.h
//  VideoBlend
//
//  Created by L了个G on 2017/12/20.
//  Copyright © 2017年 L了个G. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "LGVideoEditModel.h"
@interface LGCustomVideoCompositionInstruction :  NSObject <AVVideoCompositionInstruction>
@property CMPersistentTrackID sourceTrackID;
@property CMPersistentTrackID effectTrackID;

@property FilterType filterType;
- (id)initSourceTrackID:(CMPersistentTrackID)sourceTrackID forTimeRange:(CMTimeRange)timeRange type:(FilterType)type;
- (id)initSourceTrackID:(NSArray *)sourceTrackIDs forTimeRange:(CMTimeRange)timeRange;
@end

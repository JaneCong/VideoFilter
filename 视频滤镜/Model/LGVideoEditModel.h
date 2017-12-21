//
//  LGVideoEditModel.h
//  VideoBlend
//
//  Created by L了个G on 2017/12/20.
//  Copyright © 2017年 L了个G. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
typedef NS_ENUM(NSUInteger, FilterType) {
    FilterTypeNone = 0,
    FilterTypeColorInvert,// 反色
    FilterTypeOldSchool,// 怀旧
    FilterTypeBlackWhite,// 黑白
    FilterTypeRomance,// 浪漫
    FilterTypePainting,// 彩绘
    FilterTypeFishEye,// 鱼眼
    FilterTypeRio,// 里约大冒险
    FilterTypeCheEnShang,// 车恩尚
    FilterTypeAutumn,// 瑞秋
};
@class LGVideoEditModel;
typedef void(^CompletionBlock)(LGVideoEditModel *model);
@interface LGVideoEditModel : NSObject
@property (nonatomic) AVURLAsset  *asset;
@property (nonatomic) CMTimeRange timeRange;
@property (nonatomic) FilterType filterType;
+(void)loadResoureWithURL:(NSString *)URL completion:(CompletionBlock)completion;
@end

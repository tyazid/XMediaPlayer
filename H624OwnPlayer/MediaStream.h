//
//  MediaStream.h
//  XMediaPlayer
//
//  Created by tyazid on 22/01/2017.
//  Copyright © 2017 tyazid. All rights reserved.
//

#ifndef MediaStream_h
#define MediaStream_h
#import <Foundation/Foundation.h>
//#import "VToolBox.h"
@interface MediaStream : NSObject

typedef NS_ENUM(NSInteger, MediaStreamType) {
    MediaStreamH264Type,
    MediaStreamAC3Type,
    MediaStreamAACType
    
};

typedef NS_ENUM(NSInteger, MediaCategory) {
    MediaAudio,
    MediaVideo,
    MediaText
    
};

//NS_ASSUME_NONNULL_BEGIN
@property (strong,nonatomic,readonly,nonnull  ) NSData*  data;
@property (nonatomic,readonly) MediaStreamType type;
@property (nonatomic,readonly) MediaCategory category;
NS_ASSUME_NONNULL_BEGIN
-(instancetype) init __attribute__((unavailable("use initWithData instead")));
-(id)initWithData:(NSData* _Nonnull)data andType:(MediaStreamType)type NS_DESIGNATED_INITIALIZER;
- (NSString *)description;
  NS_ASSUME_NONNULL_END
@end
#endif /* MediaStream_h */

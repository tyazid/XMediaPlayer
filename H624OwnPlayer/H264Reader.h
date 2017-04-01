//
//  H264Reader.h
//  XMediaPlayer
//
//  Created by tyazid on 24/01/2017.
//  Copyright © 2017 tyazid. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XPCore.h"
@interface H264Reader : NSObject<MediaReader>
//@property (copy) consumeFnt consumeFrame ;
@property  id<MediaConsumer> consumeFrame ;
@property  id<MediaConsumCB> consumeCB ;

@property (readonly) MediaReaderType type;
@property (nonatomic) NSUInteger timeUs;
//consumeCB
@end


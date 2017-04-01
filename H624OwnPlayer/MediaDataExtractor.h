//
//  MediaDataExtractor.h
//  XMediaPlayer
//
//  Created by tyazid on 26/01/2017.
//  Copyright © 2017 tyazid. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XPCore.h"
@interface MediaDataExtractor :NSObject<MediaExtractor>
@property MediaExtractorCB extractorCB;

-(BOOL)extracted:(uint8_t*)buffer withSize:(NSUInteger)size;
-(BOOL)setConsumerFor:( id<MediaReader> ) reader;
@end

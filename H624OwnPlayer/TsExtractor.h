//
//  TsExtractor.h
//  XMediaPlayer
//
//  Created by tyazid on 25/01/2017.
//  Copyright © 2017 tyazid. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "XPCore.h" 
#import "MediaDataExtractor.h"
//#define TS_EXTRACTOR_DBG

@interface TsExtractor :MediaDataExtractor <MediaConsumCB>
  -(BOOL)extracted:(uint8_t*)buffer withSize:(NSUInteger)size;

@end



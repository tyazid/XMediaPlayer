//
//  VideoCodecMediaRendered.h
//  XMediaPlayer
//
//  Created by tyazid on 25/01/2017.
//  Copyright © 2017 tyazid. All rights reserved.
//

#import "CodecMediaRenderer.h"

@interface VideoCodecMediaRendered : CodecMediaRenderer
@property (strong,nonatomic) AVSampleBufferDisplayLayer* videoLayer;

@end

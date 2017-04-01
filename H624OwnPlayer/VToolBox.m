//
//  VToolBox_VToolBox_m.h
//  XMediaPlayer
//
//  Created by tyazid on 24/01/2017.
//  Copyright © 2017 tyazid. All rights reserved.
//


#import "VToolBox.h"
@interface VToolBox ()
@property  NSUInteger frameCount;
-(CMFormatDescriptionRef) createFormatDescription : (CMVideoCodecType) codecType
                                            withConfig:(CFDictionaryRef) config
                                            withWidth:(NSUInteger) width
                                            withHright:(NSUInteger) height;
@end
@implementation VToolBox

static void videotoolbox_decoder_callback(void *opaque,
                                          void *sourceFrameRefCon,
                                          OSStatus status,
                                          VTDecodeInfoFlags flags,
                                          CVImageBufferRef image_buffer,
                                          CMTime pts,
                                          CMTime duration){
}


-(CFDictionaryRef) createDecoderConfig:(CMVideoCodecType)decType {
 
    
    return CFDictionaryCreateMutable(kCFAllocatorDefault,
                                     0,
                                     &kCFTypeDictionaryKeyCallBacks,
                                     &kCFTypeDictionaryValueCallBacks);
}

-(CMFormatDescriptionRef) createFormatDescription:(CMVideoCodecType)codecType withConfig:(CFDictionaryRef)config withWidth:(NSUInteger)width withHeight:(NSUInteger)height
{

    CMFormatDescriptionRef fmtDesc;
    OSStatus status;
    
    status = CMVideoFormatDescriptionCreate(kCFAllocatorDefault,
                                            codecType,
                                            (int32_t)width,
                                           (int32_t) height,
                                            config, // Dictionary of extension
                                            &fmtDesc);
    
    if (status)
        return Nil;
    
    return fmtDesc;
}

-(BOOL) initToolBox:(CodecId)codec withWidth:(NSUInteger)width withHeight:(NSUInteger)height
{
    OSStatus status;
    VTDecompressionOutputCallbackRecord decoder_cb;
    CFDictionaryRef decoder_spec;
    CFDictionaryRef buf_attr;
    CMVideoCodecType iosCodecType;

    /*convert to ios toolbox type*/
    switch (codec) {
        case CODEC_H263_ID:
            iosCodecType = kCMVideoCodecType_H263;
            break;
        case CODEC_H264_ID:
            iosCodecType = kCMVideoCodecType_H264;
            break;
        case CODEC_MPEG4:
            iosCodecType = kCMVideoCodecType_MPEG4Video;
            break;
        case CODEC_MPEG1VIDEO_ID:
            iosCodecType = kCMVideoCodecType_MPEG1Video;
            break;
        case CODEC_MPEG2VIDEO_ID:
            iosCodecType = kCMVideoCodecType_MPEG2Video;
            break;
        default:
            //Error
            NSLog(@"Uncknown codec type : %lu",codec);
            return NO;
            break;
    }
    //CFG
    CFDictionaryRef config =CFDictionaryCreateMutable(kCFAllocatorDefault,
                                                      0,
                                                      &kCFTypeDictionaryKeyCallBacks,
                                                      &kCFTypeDictionaryValueCallBacks);
    
    CMFormatDescriptionRef fmt = (config)? [self createFormatDescription:iosCodecType
                                                              withConfig:config
                                                              withWidth:width
                                                              withHeight:height]:
                                  Nil;
    
    if(!fmt)
    {
        if(config)
            CFRelease(config);
        return NO;
    }
    
    
     decoder_cb.decompressionOutputCallback = videotoolbox_decoder_callback;

    
    //    decoder_spec = videotoolbox_decoder_config_create(videotoolbox->cm_codec_type, avctx);

    
    
    
    
      return NO;
}
@end

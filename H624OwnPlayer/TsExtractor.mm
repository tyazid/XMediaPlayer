//
//  TsExtractor.m
//  XMediaPlayer
//
//  Created by tyazid on 25/01/2017.
//  Copyright © 2017 tyazid. All rights reserved.
//

#import "TsExtractor.h"
#import "ts.h"


class MediaReaderWrapper: public ts::EsWriter
{
protected:
    void* delegate;
    //(void*)CFBridgingRetain(self)
    BOOL opened;
public:
    MediaReaderWrapper(id<MediaReader> mediareader):delegate((void*)CFBridgingRetain(mediareader) )  {}
    ~MediaReaderWrapper(void) {close();}
    
    bool open(int mode,const char* fmt,...){
#ifdef TS_EXTRACTOR_DBG
        printf(" #################@ OPEN TS DEMUX WRAPPER> %s\n",fmt);
#endif
        id oc =CFBridgingRelease(delegate) ;
        [oc  startStream];
        delegate =(void*)CFBridgingRetain(oc);
#ifdef TS_EXTRACTOR_DBG
        printf(" #################@ OPEN TS DEMUX WRAPPER <\n");
#endif

        return (opened =YES);
    }
    void close(void){
#ifdef TS_EXTRACTOR_DBG
        printf("#################@ CLOSE>\n");
#endif

        if(opened){
            id oc =CFBridgingRelease(delegate) ;
            [oc  endStream];
            delegate =(void*)CFBridgingRetain(oc);
        }
#ifdef TS_EXTRACTOR_DBG
        printf("#################@ CLOSE>\n");
#endif

        opened = NO;
    }


    int write(const char* p,u_int64_t l, bool first){
        if(delegate){
         //   printf("#################@ WRITE>\n");

            id oc =CFBridgingRelease(delegate) ;
            [oc   setPacket:p withOffset:0 andSize:l isFirst:(first?YES:NO)];
            delegate =(void*)CFBridgingRetain(oc);
          //  printf("#################@ WRITE p::%p ,,, %d <\n", p,l);


         return 0;
        }
      //  printf("#################@ WRITE<\n");

        return -1;
    }
    int flush(void){
        return 0;
    }
    int read(char* p,int l){
        return -1;}
    
    bool is_opened(void)
    { return opened; }
    
    void sigFrame(u_int64_t number){
        if(delegate){
            id oc =CFBridgingRelease(delegate) ;
            [oc   signalNewFrame:number];
            delegate =(void*)CFBridgingRetain(oc);
        }
 
        
    }
    void config(u_int64_t pts, u_int64_t dts,double fps){
      //  printf("#################@ CFG>\n");

        if(delegate){
            id oc =CFBridgingRelease(delegate) ;
            [oc   setFrameConf:pts withdts:dts withFps:fps];
            delegate =(void*)CFBridgingRetain(oc);
         }
     //   printf("#################@ CFG<\n");

    }
};


//EsWriter
@interface TsExtractor()
@property  NSDictionary<NSNumber*,id<MediaReader>>*ff;
@property  NSMutableDictionary<NSNumber*,id<MediaConsumer>>* consumers;
@end
@implementation TsExtractor

-(instancetype)init{
    
    if(self = [super init])
    {
        [self setExtractorCB:Nil] ;
    }
    return self;
}


ts::BuildEsWriter writer =  ^( ts::stream& stream, void* appData){
    if(stream.file)
        return;
    
    switch (stream.type) {
            // 0x01,0x02            - MPEG2 video
            // 0x80                 - MPEG2 video (for TS only, not M2TS)
            // 0x1b                 - H.264 video
            // 0xea                 - VC-1  video
            // 0x81,0x06,0x83       - AC3   audio
            // 0x03,0x04            - MPEG2 audio
            // 0x80                 - LPCM  audio
            // 0x82,0x86,0x8a       - DTS   audio
            
        case 0x81:
        case 0x06:
        case 0x83://ac3
        case 0x0f://aac
            //later
            break;
            
        case 0x1b: //H264
            id<MediaReader> h264r=[ MediaReaderFactory getMediaReader:H264_TYPE];
            if(h264r)

            {
                
                if(appData)
                    [ CFBridgingRelease(appData) setConsumerFor:h264r];

                 ts::EsWriter* esWriter = new MediaReaderWrapper(h264r);//Set consumer here !!!
                 stream.file = esWriter;
            }
            
            break;
                }
    
}  ;

-(BOOL)setConsumerFor:(id<MediaReader>)reader{
   if([super setConsumerFor:reader])
   {
       [reader setConsumeCB:self];
       return YES;
   }
    
    //-(BOOL)setConsumerFor:(id<MediaReader>)reader
    return NO;
}
/*-(BOOL)setConsumerFor:(id<MediaReader>)reader{
    return NO;
}*/
-(BOOL)extracted:(uint8_t *)buffer withSize:(NSUInteger)size
{
#ifdef TS_EXTRACTOR_DBG
    NSLog(@"************ In TsExTRACTOR#extracted ");
#endif

    ts::demuxer demuxer;
    demuxer.reset();
    demuxer.appData=(void*)CFBridgingRetain(self);
    demuxer.es_parse=YES;
    demuxer.av_only=YES;
    demuxer.buildWriter=writer;
    BOOL demuxed =  !demuxer.demux_buffer((const char* )buffer, size) ;
#ifdef TS_EXTRACTOR_DBG

    NSLog(@"************ TS ExTRACTOR demuxed=%i",demuxed);
#endif
    demuxer.closeFiles();
    return demuxed;
}

-(void) startConsume{
    if([self extractorCB])
        [self extractorCB](START_CONSUME);
}
-(void) endConsume{
    if([self extractorCB])
        [self extractorCB](END_CONSUME);
}

@end

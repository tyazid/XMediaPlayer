//
//  ts.h
//  XMediaPlayer
//
//  Created by tyazid on 24/01/2017.
//  Copyright © 2017 tyazid. All rights reserved.
//

#ifndef ts_h
#define ts_h
#include <sys/types.h>
#include <stdio.h>
#include <map>
#include <string>
#include <list>
#include <memory.h>
#include <stdlib.h>
#ifndef _WIN32
#include <dirent.h>
#include <getopt.h>
#include <unistd.h>
#else
#include <io.h>
#include <fcntl.h>
#include "getopt.h"
#endif
#include <string.h>
#include <time.h>
#include <sys/stat.h>
#include <memory>
#include <vector>
#include <fcntl.h>
#include <stdarg.h>


#define O_BINARY 0


#ifndef O_LARGEFILE
#define O_LARGEFILE 0
#endif


#define os_slash        '/'


namespace h264
{
    class counter
    {
    private:
        u_int32_t ctx;
        u_int64_t frame_num;                            // JVT NAL (h.264) frame counter
    public:
        counter(void):ctx(0),frame_num(0) {}
        
        void parse(const char* p,u_int64_t l, u_int64_t* startOffset)
        {
   
            for(int i=0;i<l;i++)
            {
                ctx=(ctx<<8)+((unsigned char*)p)[i];
                if((ctx&0xffffff1f)==0x00000109){    // NAL access unit
                    *startOffset=i;
                    frame_num++;
                    
                  /*  printf("~~~~~~~~~NEW FRAME : %llu L:%llu  startOffset=%llu :buff:",frame_num,l ,*startOffset );
                    for (int j =i;j<(i+8);j++) {
                        printf("%x:",((unsigned char*)p)[j]);
                    }
                    printf("\n");*/
                    
                    
                }
              }
         }
        
        u_int64_t get_frame_num(void) const { return frame_num; }
        
        void reset(void)
        {
            ctx=0;
            frame_num=0;
        }
    };
}




namespace ac3
{
    class counter
    {
    private:
        u_int16_t st;
        u_int32_t ctx;
        u_int16_t skip;
        u_int64_t frame_num;
    public:
        counter(void):st(0),ctx(0),skip(0),frame_num(0) {}
        
        void parse(const char* p,u_int64_t l, u_int64_t* startOffset)
        {
            static const u_int16_t frame_size_32khz[]=
            {
                96,96,120,120,144,144,168,168,192,192,240,240,288,288,336,336,384,384,480,480,576,576,672,672,768,768,960,
                960,1152,1152,1344,1344,1536,1536,1728,1728,1920,1920
            };
            static const u_int16_t frame_size_44khz[]=
            {
                69,70,87,88,104,105,121,122,139,140,174,175,208,209,243,244,278,279,348,349,417,418,487,488,557,558,696,
                697,835,836,975,976,1114,1115,1253,1254,1393,1394
            };
            static const u_int16_t frame_size_48khz[]=
            {
                64,64,80,80,96,96,112,112,128,128,160,160,192,192,224,224,256,256,320,320,384,384,448,448,512,512,640,640,
                768,768,896,896,1024,1024,1152,1152,1280,1280
            };
            
            for(int i=0;i<l;)
            {
                if(skip>0)
                {
                    int n=l-i;
                    if(n>skip)
                        n=skip;
                    i+=n;
                    skip-=n;
                    
                    if(i>=l)
                        break;
                }
                
                
                ctx=(ctx<<8)+((unsigned char*)p)[i];
                
                switch(st)
                {
                    case 0:             // wait 0x0b77 marker
                        if((ctx&0xffff0000)==0x0b770000)
                        {
                            st++;
                            frame_num++;
                        }
                        break;
                    case 1:
                        st++;
                        break;
                    case 2:
                    {
                        int frmsizecod=(ctx>>8)&0x3f;
                        if(frmsizecod>37)
                            frmsizecod=0;
                        
                        int framesize=0;
                        
                        switch((ctx>>14)&0x03)
                        {
                            case 0: framesize=frame_size_48khz[frmsizecod]; break;
                            case 1: framesize=frame_size_44khz[frmsizecod]; break;
                            case 2: framesize=frame_size_32khz[frmsizecod]; break;
                        }
                        
                        skip=framesize*2-6;
                        
                        st=0;
                        break;
                    }
                }
                
                i++;
                
            }
        }
        u_int64_t get_frame_num(void) const { return frame_num; }
        
        void reset(void)
        {
            st=0;
            ctx=0;
            skip=0;
            frame_num=0;
        }
    };
}


namespace ts
{
    class stream;
    class  EsWriter;
    typedef  void (^BuildEsWriter)(ts::stream& stream, void* appData);
    inline u_int8_t to_byte(const char* p)
    { return *((unsigned char*)p); }
    
    inline u_int16_t to_int(const char* p)
    { u_int16_t n=((unsigned char*)p)[0]; n<<=8; n+=((unsigned char*)p)[1]; return n; }
    
    inline u_int32_t to_int32(const char* p)
    {
        u_int32_t n=((unsigned char*)p)[0];
        n<<=8; n+=((unsigned char*)p)[1];
        n<<=8; n+=((unsigned char*)p)[2];
        n<<=8; n+=((unsigned char*)p)[3];
        return n;
    }
    
    class table
    {
    public:
        enum { max_buf_len=512 };
        
        char buf[max_buf_len];
        
        u_int16_t len;
        
        u_int16_t offset;
        
        table(void):offset(0),len(0) {}
        
        void reset(void) { offset=0; len=0; }
    };
    class EsWriter
    {
    public:
        EsWriter(void)  {}
        ~EsWriter(void){}
        
        enum { in=0, out=1 };
    public:
        std::string filename;
        virtual  bool open(int mode,const char* fmt,...)=0;
        virtual    void close(void)=0;
        virtual   int write(const char* p,u_int64_t l, bool first)=0;
        virtual   void sigFrame(u_int64_t)=0;
        virtual    int flush(void)=0;
        virtual    int read(char* p,int l)=0;
        virtual     void config(u_int64_t pts, u_int64_t dts,double fps)=0;
        virtual     bool is_opened(void)=0;
    };
    
    class file: public EsWriter
    {
    protected:
        int fd;
        enum { max_buf_len=2048 };
        char buf[max_buf_len];
        int len,offset;
   
    public:
        file(void):fd(-1),len(0),offset(0) {}
        ~file(void);
        enum { in=0, out=1 };
        bool open(int mode,const char* fmt,...);
        void close(void);
        int write(const char* p,u_int64_t l,bool first);
        int flush(void);
        int read(char* p,int l);
        void config(u_int64_t pts, u_int64_t dts,double fps){}
        void sigFrame(u_int64_t number){}
       bool is_opened(void) { return fd==-1?false:true; }
    };
    
   
    namespace stream_type
    {
        enum
        {
            data                = 0,
            mpeg2_video         = 1,
            h264_video          = 2,
            vc1_video           = 3,
            ac3_audio           = 4,
            mpeg2_audio         = 5,
            lpcm_audio          = 6,
            dts_audio           = 7,
            aac_audio           = 8
        };
    }
    
    class counter_ac3
    {
    private:
    public:
        counter_ac3(void) {}
        
        void parse(const char* p,int l, u_int64_t* startOffset)
        {
        }
        
        u_int64_t get_frame_num(void) const { return 0; }
        
        void reset(void)
        {
        }
    };
    class counter_aac
    {
    private:
    public:
        counter_aac(void) {}
        
        void parse(const char* p,int l, u_int64_t* startOffset)
        {
        }
        
        u_int64_t get_frame_num(void) const { return 0; }
        
        void reset(void)
        {
        }
    };
    
    
    class stream
    {
    public:
        u_int16_t channel;                      // channel number (1,2 ...)
        u_int8_t  id;                           // stream number in channel
        u_int8_t  type;                         // 0xff                 - not ES
        // 0x01,0x02            - MPEG2 video
        // 0x80                 - MPEG2 video (for TS only, not M2TS)
        // 0x1b                 - H.264 video
        // 0xea                 - VC-1  video
        // 0x81,0x06,0x83       - AC3   audio
        // 0x03,0x04            - MPEG2 audio
        // 0x80                 - LPCM  audio
        // 0x82,0x86,0x8a       - DTS   audio
        // 0x0f                 - AAC   audio
        table psi;                              // PAT,PMT cache (only for PSI streams)
        
        u_int8_t stream_id;                     // MPEG stream id
        
        ts::EsWriter* file;                          // output ES file
        FILE* timecodes;
        
        u_int64_t dts;                          // current MPEG stream DTS (presentation time for audio, decode time for video)
        u_int64_t first_dts;
        u_int64_t first_pts;
        u_int64_t last_pts;
        u_int32_t frame_length;                 // frame length in ticks (90 ticks = 1 ms, 90000/frame_length=fps)
        u_int64_t frame_num;                    // frame counter
        
        h264::counter frame_num_h264;           // JVT NAL (h.264) frame counter
        ac3::counter  frame_num_ac3;            // A/52B (AC3) frame counter
        
        stream(void):channel(0xffff),id(0),type(0xff),stream_id(0),
        dts(0),first_dts(0),first_pts(0),last_pts(0),frame_length(0),frame_num(0),timecodes(0),file(0) {}
        
        ~stream(void);
        
        void reset(void)
        {
            psi.reset();
            dts=first_pts=last_pts=0;
            frame_length=0;
            frame_num=0;
            frame_num_h264.reset();
            frame_num_ac3.reset();
        }
        
        u_int64_t get_es_frame_num(void) const
        {
            if(frame_num_h264.get_frame_num())
                return frame_num_h264.get_frame_num();
            
            if(frame_num_ac3.get_frame_num())
                return frame_num_ac3.get_frame_num();
            
            return 0;
        }
    };
    
    
    class demuxer
    {
    public:
        std::map<u_int16_t,stream> streams;
        bool hdmv;                                      // HDMV mode, using 192 bytes packets
        bool av_only;                                   // Audio/Video streams only
        bool parse_only;                                // no demux
        int dump;                                       // 0 - no dump, 1 - dump M2TS timecodes, 2 - dump PTS/DTS, 3 - dump tracks
        int channel;                                    // channel for demux
        int pes_output;                                 // demux to PES
        std::string prefix;                             // output file name prefix (autodetect)
        std::string dst;                                // output directory
        bool verb;                                      // verbose mode
        bool es_parse;
        
    public:
        u_int64_t base_pts;
        std::string subs_filename;
        BuildEsWriter buildWriter;
        void* appData;
    protected:
        FILE* subs;
        u_int32_t subs_num;
        
        bool validate_type(u_int8_t type);
        u_int64_t decode_pts(const char* ptr);
        bool is_video_stream_type(u_int8_t type);
        int get_stream_type(u_int8_t type);
        const char* get_stream_ext(u_int8_t type_id);
        
        // take 188/192 bytes TS/M2TS packet
        int demux_ts_packet(const char* ptr);
        
        void write_timecodes(FILE* fp,u_int64_t first_pts,u_int64_t last_pts,u_int32_t frame_num,u_int32_t frame_len);
#ifndef OLD_TIMECODES
        void write_timecodes2(FILE* fp,u_int64_t first_pts,u_int64_t last_pts,u_int32_t frame_num,u_int32_t frame_len);
#endif
    public:
        demuxer(void):hdmv(false),av_only(true),parse_only(false),dump(0),
                      channel(0),base_pts(0),pes_output(0),verb(false),es_parse(false),subs(0),subs_num(0),appData(0) {}
        ~demuxer(void) { if(subs) fclose(subs); }
        
        void show(void);
        
        int demux_file(const char* name);
        int demux_buffer(const char* buffer, size_t size );
        void closeFiles(void);

        int gen_timecodes(const std::string& datetime);
        
        void reset(void)
        {
            for(std::map<u_int16_t,stream>::iterator i=streams.begin();i!=streams.end();++i)
                i->second.reset();
        }
    };
    
    const char* timecode_to_time(u_int32_t timecode);
}


#endif /* ts_h */

/*

 Copyright (C) 2009 Anton Burdinuk

 clark15b@gmail.com

*/



#include "ts.h"
 /*******/



/*
 
 Copyright (C) 2009 Anton Burdinuk
 
 clark15b@gmail.com
 
 */

#ifndef __TS_H
#define __TS_H







#endif

/***********/

//#include "ts.h"

// TODO: join TS

// 1) M2TS timecode (0-1073741823)
/*
The extra 4-byte header is composed of two fields. The upper 2 bits are the copy_permission_indicator and the lower 30 bits are the arrival_time_stamp. The arrival_time_stamp is equal to the lower 30 bits of the 27 MHz STC at the 0x47 byte of the Transport packet. In a packet that contains a PCR, the PCR will be a few ticks later than the arrival_time_stamp. The exact difference between the arrival_time_stamp and the PCR (and the number of bits between them) indicates the intended fixed bitrate of the variable rate Transport Stream.

The primary function is to allow the variable rate Transport Stream to be converted to a fixed rate stream before decoding (since only fixed rate Transport Streams fit into the T-STD buffering model).

It doesn't really help for random access. 30 bits at 27 MHz only represents 39.77 seconds.
*/

// 2) TS Continuity counter (0-15..0-15..)
// 3) PES PTS/DTS
#define __printf__(fmt,...) do {printf(stderr, "%s:%d:%s(): " fmt, __FILE__, \
__LINE__, __func__, __VA_ARGS__);}while(0);
namespace ts
{
    static bool DBG = false;
    void get_prefix_name_by_filename(const std::string& s,std::string& name);
#ifdef _WIN32
    void my_strptime(const char* s,tm* t);
#endif
}

const char* ts::timecode_to_time(u_int32_t timecode)
{
    static char buf[128];
    
    int msec=timecode%1000;
    timecode/=1000;
    
    int sec=timecode%60;
    timecode/=60;
    
    int min=timecode%60;
    timecode/=60;
    
    sprintf(buf,"%.2i:%.2i:%.2i.%.3i",(int)timecode,min,sec,msec);
    
    return buf;
}

ts::stream::~stream(void)
{
    if(timecodes)
        fclose(timecodes);
    if(this->file)
        delete this->file;
}


void ts::get_prefix_name_by_filename(const std::string& s,std::string& name)
{
    int ll=s.length();
    const char* p=s.c_str();

    while(ll>0)
    {
        if(p[ll-1]=='/' || p[ll-1]=='\\')
            break;
        ll--;
    }

    p+=ll;

    int cn=0;

    const char* pp=strchr(p,'.');

    if(pp)
        name.assign(p,pp-p);
}




ts::file::~file(void)
{
    //~EsWriter()
    close();
}

bool ts::file::open(int mode,const char* fmt,...)
{
    filename.clear();

    char name[512];

    va_list ap;
    va_start(ap,fmt);
    vsprintf(name,fmt,ap);
    va_end(ap);

    int flags=0;

    switch(mode)
    {
    case in:
        flags=O_LARGEFILE|O_BINARY|O_RDONLY;
        break;
    case out:
        flags=O_CREAT|O_TRUNC|O_LARGEFILE|O_BINARY|O_WRONLY;
        break;
    }

    fd=::open(name,flags,0644);

    if(fd!=-1)
    {
        filename=name;
        len=offset=0;
        return true;
    }

    fprintf(stderr,"can`t open file %s\n",name);

    return false;
}


void ts::file::close(void)
{
    if(fd!=-1)
    {
        flush();
        ::close(fd);
        fd=-1;
    }
    len=0;
    offset=0;
}

int ts::file::flush(void)
{
    int l=0;

    while(l<len)
    {
        int n=::write(fd,buf+l,len-l);
        if(!n || n==-1)
            break;
        l+=n;
    }

    len=0;

    return l;
}

int ts::file::write(const char* p,u_int64_t l,bool first)
{
    int rc=l;

    while(l>0)
    {
        if(len>=max_buf_len)
            flush();

        int n=max_buf_len-len;

        if(n>l)
            n=l;

        memcpy(buf+len,p,n);
        len+=n;

        p+=n;
        l-=n;
    }

    return rc;
}
int ts::file::read(char* p,int l)
{
    const char* tmp=p;

    while(l>0)
    {
        int n=len-offset;

        if(n>0)
        {
            if(n>l)
                n=l;

            memcpy(p,buf+offset,n);
            p+=n;
            offset+=n;
            l-=n;
        }else
        {
            int m=::read(fd,buf,max_buf_len);
            if(m==-1 || !m)
                break;
            len=m;
            offset=0;
        }
    }

    return p-tmp;
}


bool ts::demuxer::validate_type(u_int8_t type)
{
    if(av_only)
        return strchr("\x01\x02\x80\x1b\xea\x81\x06\x83\x03\x04\x82\x86\x8a\x0f",type)?true:false;

    return true;
}

int ts::demuxer::get_stream_type(u_int8_t type)
{
    if(DBG)printf("######## GET STREAM TYPE :%x\n",type);
    switch(type)
    {
    case 0x01:
    case 0x02:
        return stream_type::mpeg2_video;
    case 0x80:
        return hdmv?stream_type::lpcm_audio:stream_type::mpeg2_video;
    case 0x1b:
           if(DBG) printf("######## GET STREAM TYPE h264_video\n");

        return stream_type::h264_video;
    case 0xea:
        return stream_type::vc1_video;
    case 0x81:
    case 0x06:
    case 0x83:
        return stream_type::ac3_audio;
    case 0x03:
    case 0x04:
        return stream_type::mpeg2_audio;
    case 0x82:
    case 0x86:
    case 0x8a:
        return stream_type::dts_audio;
    case 0x0f:
        return stream_type::aac_audio;

    }
    return stream_type::data;
}

const char* ts::demuxer::get_stream_ext(u_int8_t type_id)
{
    static const char* list[9]= { "sup", "m2v", "264", "vc1", "ac3", "m2a", "pcm", "dts", "aac" };

    if(type_id<0 || type_id>=9)
        type_id=0;

    return list[type_id];
}

u_int64_t ts::demuxer::decode_pts(const char* ptr)
{
    const unsigned char* p=(const unsigned char*)ptr;

    u_int64_t pts=((p[0]&0xe)<<29);
    pts|=((p[1]&0xff)<<22);
    pts|=((p[2]&0xfe)<<14);
    pts|=((p[3]&0xff)<<7);
    pts|=((p[4]&0xfe)>>1);

    return pts;
}
bool ts::demuxer::is_video_stream_type(u_int8_t type)
{
        switch(type)
        {
                    case 0x01:
                    case 0x02:
                    case 0x1b:
                    case 0xea:
                        return true;
                    case 0x80:
                        return hdmv?false : true;
                    case 0x81:
                    case 0x06:
                    case 0x83:
                    case 0x03:
                    case 0x04:
                    case 0x82:
                    case 0x86:
                    case 0x8a:
                    default:
                        return false;
             }
     }
void ts::demuxer::closeFiles(){
    
    for(std::map<u_int16_t,ts::stream>::const_iterator i=streams.begin();i!=streams.end();++i)
    {
        const ts::stream& s=i->second;
        if(s.file)
            s.file->close();
        
       
    }
    
}
int ts::demuxer::demux_ts_packet(const char* ptr)
{
    u_int32_t timecode=0;
    if(hdmv)
    {
        timecode=to_int32(ptr)&0x3fffffff;
        ptr+=4;
    }

    const char* end_ptr=ptr+188;

    if(ptr[0]!=0x47)            // ts sync byte
        return -1;

    u_int16_t pid=to_int(ptr+1);
    u_int8_t flags=to_byte(ptr+3);

    bool transport_error=pid&0x8000;
    bool payload_unit_start_indicator=pid&0x4000;
    bool adaptation_field_exist=flags&0x20;
    bool payload_data_exist=flags&0x10;
    u_int8_t continuity_counter=flags&0x0f;
    pid&=0x1fff;

    if(transport_error)
        return -2;

    if(pid==0x1fff || !payload_data_exist)
        return 0;

    ptr+=4;

    // skip adaptation field
    if(adaptation_field_exist)
    {
        ptr+=to_byte(ptr)+1;
        if(ptr>=end_ptr)
            return -3;
    }

    if(dump==1)
      if(DBG)  printf("%.4x: [%c%c%c%c] %u.%i\n",
            pid,
            transport_error?'e':'-',
            payload_data_exist?'p':'-',
            payload_unit_start_indicator?'s':'-',
            adaptation_field_exist?'a':'-',
            timecode,
            continuity_counter
            );


    stream& s=streams[pid];
   // printf("#######0 stream ch : %d\n",s.channel);

    if(!pid || (s.channel!=0xffff && s.type==0xff))
    {
        // PSI

        if(payload_unit_start_indicator)
        {
            // begin of PSI table

            ptr++;

            if(ptr>=end_ptr)
                return -4;

            if(*ptr!=0x00 && *ptr!=0x02)
                return 0;

            if(end_ptr-ptr<3)
                return -5;

            u_int16_t l=to_int(ptr+1);

            if(l&0x3000!=0x3000)
                return -6;

            l&=0x0fff;

            ptr+=3;

            int len=end_ptr-ptr;

            if(l>len)
            {
                if(l>ts::table::max_buf_len)
                    return -7;

                s.psi.reset();

                memcpy(s.psi.buf,ptr,len);
                s.psi.offset+=len;
                s.psi.len=l;

                return 0;
            }else
                end_ptr=ptr+l;
        }else
        {
            // next part of PSI
            if(!s.psi.offset)
                return -8;

            int len=end_ptr-ptr;

            if(len>ts::table::max_buf_len-s.psi.offset)
                return -9;

            memcpy(s.psi.buf+s.psi.offset,ptr,len);
            s.psi.offset+=len;

            if(s.psi.offset<s.psi.len)
                return 0;
            else
            {
                ptr=s.psi.buf;
                end_ptr=ptr+s.psi.len;
            }
        }

        if(!pid)
        {
            // PAT

            ptr+=5;

            if(ptr>=end_ptr)
                return -10;

            int len=end_ptr-ptr-4;

            if(len<0 || len%4)
                return -11;

            int n=len/4;

            for(int i=0;i<n;i++,ptr+=4)
            {
                u_int16_t channel=to_int(ptr);
                u_int16_t pid=to_int(ptr+2);

                if(pid&0xe000!=0xe000)
                    return -12;

                pid&=0x1fff;

                if(!demuxer::channel || demuxer::channel==channel)
                {
                    stream& ss=streams[pid];
                    ss.channel=channel;
                    ss.type=0xff;
                }
            }
        }else
        {
            // PMT

            ptr+=7;

            if(ptr>=end_ptr)
                return -13;

            u_int16_t info_len=to_int(ptr)&0x0fff;

            ptr+=info_len+2;
            end_ptr-=4;

            if(ptr>=end_ptr)
                return -14;

            while(ptr<end_ptr)
            {
                if(end_ptr-ptr<5)
                    return -15;

                u_int8_t type=to_byte(ptr);
                u_int16_t pid=to_int(ptr+1);

                if(pid&0xe000!=0xe000)
                    return -16;

                pid&=0x1fff;

                info_len=to_int(ptr+3)&0x0fff;

                ptr+=5+info_len;

                // ignore unknown streams
                if(validate_type(type))
                {
                    stream& ss=streams[pid];

                    if(ss.channel!=s.channel || ss.type!=type)
                    {
                        ss.channel=s.channel;
                        ss.type=type;
                        ss.id=++s.id;
                        
                        
                       if(DBG) printf(">>>> %p",ss.file);
                        if(!ss.file && this->buildWriter)
                        {
                            this->buildWriter(ss, this->appData);
                        }
                         
                        if(!parse_only && ss.file &&  !ss.file->is_opened())
                        {
                            
                            
                            if(dst.length()){
                               if(DBG) printf("~~~~~~~~~~~~~~~~~~1 FILE NAME : %s%c%strack_%i.%s\n",dst.c_str(),os_slash,prefix.c_str(),pid,get_stream_ext(get_stream_type(ss.type)));
                                ss.file->open(file::out,"%s%c%strack_%i.%s",dst.c_str(),os_slash,prefix.c_str(),pid,get_stream_ext(get_stream_type(ss.type)));
                            }
                            else{
                              if(DBG)  printf("~~~~~~~~~~~~~~~~~~2  FILE NAME :%strack_%i.%s\n",prefix.c_str(),pid,get_stream_ext(get_stream_type(ss.type)));

                                ss.file->open(file::out,"%strack_%i.%s",prefix.c_str(),pid,get_stream_ext(get_stream_type(ss.type)));
                            }
                        }
                    }
                }
            }

            if(ptr!=end_ptr)
                return -18;
        }
    }else
    {
        if(s.type!=0xff)
        {
            // PES

            if(payload_unit_start_indicator)
            {
                s.psi.reset();
                s.psi.len=9;
            }

            while(s.psi.offset<s.psi.len)
            {
                int len=end_ptr-ptr;

                if(len<=0)
                    return 0;

                int n=s.psi.len-s.psi.offset;

                if(len>n)
                    len=n;

                memcpy(s.psi.buf+s.psi.offset,ptr,len);
                s.psi.offset+=len;

                ptr+=len;

                if(s.psi.len==9)
                    s.psi.len+=to_byte(s.psi.buf+8);
            }

            if(s.psi.len)
            {
                if(memcmp(s.psi.buf,"\x00\x00\x01",3))
                    return -19;

                s.stream_id=to_byte(s.psi.buf+3);

                u_int8_t flags=to_byte(s.psi.buf+7);

                s.frame_num++;

                switch(flags&0xc0)
                {
                case 0x80:          // PTS only
                    {                       if(DBG)  printf("********** PTS ONLY\n");

                        u_int64_t pts=decode_pts(s.psi.buf+9);

                        if(dump==2){
                            if(DBG)
                            printf("%.4x: %llu\n",pid,pts);
                        }else if(dump==3){
                            if(DBG)
                            printf("%.4x: track=%.4x.%.2i, type=%.2x, stream=%.2x, pts=%llums\n",pid,s.channel,s.id,s.type,s.stream_id,pts/90);
                          }
                        if(s.dts>0 && pts>s.dts){
                            //printf("********** FRAME L=%llu\n",pts-s.dts);
                            s.frame_length=pts-s.dts;
                            if(is_video_stream_type(s.type))
                                {
                                 if(DBG)
                                  printf("frame rate:%d: %f\n",s.frame_length,(90000./(double)s.frame_length));///TYAZ
                                    

                              }

                        }
                        s.dts=pts;

                        if(pts>s.last_pts)
                            s.last_pts=pts;

                        if(!s.first_pts)
                            s.first_pts=pts;
                        if(s.file && s.frame_length){
                            s.file->config(pts/90, pts/90, (90000./(double)s.frame_length));
                        }
                    }
                    break;
                case 0xc0:          // PTS,DTS
                    {
                    
                                           ///    printf("**********PTS,DTS counter:%d\n",++counter0);

                        u_int64_t pts=decode_pts(s.psi.buf+9);
                        u_int64_t dts=decode_pts(s.psi.buf+14);

                       

                        if(s.dts>0 && dts>s.dts)
                            s.frame_length=dts-s.dts;
                        s.dts=dts;
                        
                        if(dump==2){
                          if(DBG)  printf("%.4x: %llu %llu\n",pid,pts,dts);
                        }
                        else if(dump==3||1){
                         if(DBG)   printf("%d   .4x: track=%.4x.%.2i, type=%.2x, stream=%.2x, pts=%llums, dts=%llums frame_length=%u AT %p\n",pid,s.channel,s.id,s.type,s.stream_id,pts/90,dts/90, s.frame_length,ptr);
                        }
                       if(DBG) printf("frame rate:%d: %f\n",s.frame_length,(90000./(double)s.frame_length));///TYAZ

                        
                        //config

                        if(pts>s.last_pts)
                            s.last_pts=pts;

                        if(!s.first_dts)
                            s.first_dts=dts;
                        if(s.file /*&& s.frame_length*/){
                            s.file->config(pts/90, dts/90,s.frame_length? (90000./(double)s.frame_length):24.f);
                        }
                    }
                    break;
                }

                if( DBG){
                int hh = 0;
                    static unsigned long counter0 = 0;
                printf("\n  dump psi   ==>  " );
                counter0 =(unsigned long) ptr;
                for (hh=0; hh<48;hh++)
                    printf("%.2x:",ptr[hh]&0xff);
                printf("\n");
            }

                if(pes_output && s.file && s.file->is_opened()){
                        s.file->write(s.psi.buf,s.psi.len , false);
                }

                s.psi.reset();
            }

            if(s.frame_num)
            {
                u_int64_t len=end_ptr-ptr;
                u_int64_t frame_num= s.frame_num_h264.get_frame_num();                            // JVT NAL (h.264) frame counter
                u_int64_t startOffset=0;
 
                if(es_parse)
                {
                    switch(s.type)
                    {
                    case 0x1b:
                            
                         //  printf("********** H264 FRAME :%llu,- P.Len:%d\n",s.frame_num_h264.get_frame_num(),len);
                        s.frame_num_h264.parse(ptr,len,&startOffset);
                            
                        break;
                    case 0x06:
                    case 0x81:
                            
                    case 0x83:
                        case 0x0f://AAC

                        s.frame_num_ac3.parse(ptr,len,&startOffset);
                         //   printf("\n********** AUDIO PID (%x)  frame num:%llu \n",s.type , s.get_es_frame_num() );//,s.type,len);

                         break;
                    }
                }

              //  printf("********** write packet(%.2x)  ,len:%d\n" ,s.type,len);
                 if(s.file && s.file->is_opened()){
                      u_int64_t fnum = s.type ==0x1b ?s.frame_num_h264.get_frame_num() : s.frame_num_ac3.get_frame_num();
                    if( frame_num!=   fnum){
                        
                        s.file->sigFrame(fnum);
                        
                        if( DBG){
                            printf("\n********** start write  new frame. %llu ::: \n",fnum  );//,s.type,len);
                            
                            int hh = 0;
                            static unsigned long counter0 = 0;
                            printf("  dump psi::" );
                            counter0 =(unsigned long) ptr;
                            for (hh=0; hh<16;hh++)
                                printf("%.2x:",ptr[+startOffset+hh]&0xff);
                            printf("\n");
                        }
                    }
                     startOffset=0;
                     //ofsset.
                    s.file->write(ptr ,len , frame_num!=fnum);
                }
            }
        }
    }

    return 0;
}

void ts::demuxer::show(void)
{
    u_int64_t beg_pts=0,end_pts=0;

    for(std::map<u_int16_t,ts::stream>::const_iterator i=streams.begin();i!=streams.end();++i)
    {
        const ts::stream& s=i->second;

        if(s.type!=0xff)
        {
            if(s.first_pts<beg_pts || !beg_pts)
                beg_pts=s.first_pts;

            u_int64_t n=s.last_pts+s.frame_length;
            if(n>end_pts || !end_pts)
                end_pts=n;
        }
    }

    for(std::map<u_int16_t,ts::stream>::const_iterator i=streams.begin();i!=streams.end();++i)
    {
        u_int16_t pid=i->first;
        const ts::stream& s=i->second;

        if(s.type!=0xff)
        {
            u_int64_t end=s.last_pts+s.frame_length;
            u_int64_t len=end-s.first_pts;

            fprintf(stderr,"pid=%i (0x%.4x), ch=%i, id=%.i, type=0x%.2x (%s), stream=0x%.2x",
                pid,pid,s.channel,s.id,s.type,get_stream_ext(get_stream_type(s.type)),s.stream_id);

            if(s.frame_length>0)
                fprintf(stderr,", fps=%.2f",90000./(double)s.frame_length);

            if(len>0)
                fprintf(stderr,", len=%llums",len/90);


            if(s.frame_num>0)
                fprintf(stderr,", fn=%llu",s.frame_num);

            u_int64_t esfn=s.get_es_frame_num();

            if(esfn>0)
                fprintf(stderr,", esfn=%llu",esfn);

            if(s.first_pts>beg_pts)
            {
                u_int32_t n=(s.first_pts-beg_pts)/90;

                fprintf(stderr,", head=+%ums",n);
            }

            if(end<end_pts)
            {
                u_int32_t n=(end_pts-end)/90;

                fprintf(stderr,", tail=-%ums",n);
            }

            fprintf(stderr,"\n");
        }
    }
}

int ts::demuxer::demux_file(const char* name)
{
    prefix.clear();

    char buf[192];

    int buf_len=0;

   ts::file file;
    if(DBG)printf("************** name : %s\n",name);

    if(!file.open(file::in,"%s",name))
    {
        fprintf(stderr,"can`t open file %s\n",name);
        return -1;
    }

    get_prefix_name_by_filename(name,prefix);
    if(prefix.length())
        prefix+='.';

    for(u_int64_t pn=1;;pn++)
    {
        if(buf_len)
        {
            if(file.read(buf,buf_len)!=buf_len)
                break;
        }else
        {
            if(file.read(buf,188)!=188)
                break;
            if(buf[0]==0x47 && buf[4]!=0x47)
            {
                buf_len=188;
                fprintf(stderr,"TS stream detected in %s (packet length=%i)\n",name,buf_len);
                hdmv=false;
            }else if(buf[0]!=0x47 && buf[4]==0x47)
            {
                if(file.read(buf+188,4)!=4)
                    break;
                buf_len=192;
                fprintf(stderr,"M2TS stream detected in %s (packet length=%i)\n",name,buf_len);
                hdmv=true;
            }else
            {
                fprintf(stderr,"unknown stream type in %s\n",name);
                return -1;
            }
        }

        int n;
        if((n=demux_ts_packet(buf)))
        {
            fprintf(stderr,"%s: invalid packet %llu (%i)\n",name,pn,n);
            return -1;
        }
    }

    return 0;
}

#define readBufer(buffer,size, buf, buf_len,pos)   if(size - pos < buf_len) \
                                            break;\
                                            memcpy(buf, &buffer[pos], buf_len);\
                                            pos+=buf_len;


int ts::demuxer::demux_buffer(const char* buffer, size_t size )
{
    prefix.clear();
    
    char buf[192];
    
    int buf_len=0;
    
    int pos =0;
    
    if(DBG) printf("************** size : %lu\n",size);
    
   if(DBG) printf("#######0 STREAMS : %d\n",streams.size());

    
    for(u_int64_t pn=1;;pn++)
    {
        if(buf_len)
        {
            readBufer(buffer,size, buf, buf_len,pos);
            
            
         }else
        {
             readBufer(buffer,size, buf, 188,pos);
            
            if(buf[0]==0x47 && buf[4]!=0x47)
            {
                buf_len=188;
                fprintf(stderr,"TS stream detected  (packet length=%i)\n",buf_len);
                hdmv=false;
            }else if(buf[0]!=0x47 && buf[4]==0x47)
            {
                readBufer(buffer,size, &buf[188], 4,pos);
                buf_len=192;
                fprintf(stderr,"M2TS stream detected  (packet length=%i)\n",buf_len);
                hdmv=true;
            }else
            {
                fprintf(stderr,"unknown stream type \n");
                return -1;
            }
        }
        
        int n;
       // fprintf(stderr," DEMUX BUF 0-4  @ pos:%d(%x,%x,%x,%x)\n",pos,(int)buf[0],(int)buf[1],(int)buf[2],(int)buf[3]);

        if((n=demux_ts_packet(buf)))
        {
            fprintf(stderr," invalid packet %llu (%i)\n",pn,n);
            return -1;
        }
    }
    
    return 0;
}


#ifdef _WIN32
void ts::my_strptime(const char* s,tm* t)
{
    memset((char*)t,0,sizeof(tm));
    sscanf(s,"%d-%d-%d %d:%d:%d",&t->tm_year,&t->tm_mon,&t->tm_mday,&t->tm_hour,&t->tm_min,&t->tm_sec);
    t->tm_year-=1900;
    t->tm_mon-=1;
    t->tm_isdst=1;
}
#endif

int ts::demuxer::gen_timecodes(const std::string& datetime)
{
    u_int64_t beg_pts=0;
    u_int64_t end_pts=0;

    for(std::map<u_int16_t,stream>::iterator i=streams.begin();i!=streams.end();++i)
    {
        u_int16_t pid=i->first;
        ts::stream& s=i->second;

        if(s.type!=0xff)
        {
            if(!s.timecodes && s.file && s.file->filename.length())
            {
                std::string::size_type n=s.file->filename.find_last_of('.');
                if(n!=std::string::npos)
                {
                    std::string filename=s.file->filename.substr(0,n);
                    filename+=".tmc";

                    s.timecodes=fopen(filename.c_str(),"w");

                    if(s.timecodes)
                        fprintf(s.timecodes,"# timecode format v2\n");
                }
            }
            if(s.timecodes)
            {
                if(s.first_pts<beg_pts || !beg_pts)
                    beg_pts=s.first_pts;

                u_int64_t len=s.last_pts+s.frame_length;

                if(len>end_pts || !end_pts)
                    end_pts=len;
            }
        }
    }


    for(std::map<u_int16_t,stream>::iterator i=streams.begin();i!=streams.end();++i)
    {
        u_int16_t pid=i->first;
        ts::stream& s=i->second;

        if(s.timecodes)
        {
            u_int64_t esfn=s.get_es_frame_num();

            u_int64_t frame_num=esfn?esfn:s.frame_num;

#ifdef OLD_TIMECODES
            write_timecodes(s.timecodes,base_pts+(s.first_pts-beg_pts),base_pts+(s.last_pts+s.frame_length-beg_pts),frame_num,s.frame_length);
#else
            switch(get_stream_type(s.type))
            {
            case stream_type::ac3_audio:
            case stream_type::mpeg2_audio:
            case stream_type::lpcm_audio:
            case stream_type::aac_audio:
                write_timecodes2(s.timecodes,base_pts+(s.first_pts-beg_pts),base_pts+(s.last_pts+s.frame_length-beg_pts),frame_num,s.frame_length);
                break;
            default:
                write_timecodes(s.timecodes,base_pts+(s.first_pts-beg_pts),base_pts+(s.last_pts+s.frame_length-beg_pts),frame_num,s.frame_length);
                break;
            }
#endif
        }
    }

    if(!subs && datetime.length())
    {
        char path[512];
        sprintf(path,"%s%ctimecodes.srt",dst.c_str(),os_slash);

        subs=fopen(path,"w");

        if(subs)
            subs_filename=path;
    }

    u_int64_t length=end_pts-beg_pts;

    if(subs && datetime.length())
    {
        u_int32_t cur=base_pts/90;

        u_int32_t num=(length/90)/1000;

        time_t timecode=0;

        tm t;
#ifdef _WIN32
        my_strptime(datetime.c_str(),&t);
#else
        strptime(datetime.c_str(),"%Y-%m-%d %H:%M:%S",&t);
#endif
        timecode=mktime(&t);

        for(u_int32_t i=0;i<num;i++)
        {
            std::string start=ts::timecode_to_time(cur);

            if(i<num-1)
                cur+=1000;
            else
                cur=(base_pts+length)/90;

            std::string end=ts::timecode_to_time(cur-1);

            start[8]=',';
            end[8]=',';

#ifdef _WIN32
            localtime_s(&t,&timecode);
#else
            localtime_r(&timecode,&t);
#endif

            char timecode_s[64];
            strftime(timecode_s,sizeof(timecode_s),"%Y-%m-%d %H:%M:%S",&t);

            fprintf(subs,"%u\n%s --> %s\n%s\n\n",++subs_num,start.c_str(),end.c_str(),timecode_s);

            timecode+=1;
        }
    }


    base_pts+=length;

#ifndef OLD_TIMECODES
    // align
    if(base_pts%90)
        base_pts=base_pts/90*90+90;
#endif

    return 0;
}

void ts::demuxer::write_timecodes(FILE* fp,u_int64_t first_pts,u_int64_t last_pts,u_int32_t frame_num,u_int32_t frame_len)
{
    u_int64_t len=last_pts-first_pts;

    double c=(double)len/(double)frame_num;

    double m=0;
    u_int32_t n=0;

    for(int i=0;i<frame_num;i++)
    {
        fprintf(fp,"%llu\n",(first_pts+n)/90);

        m+=c;
        n+=c;

        if(m-n>=1)
            n+=1;
    }
}

#ifndef OLD_TIMECODES
// for audio
void ts::demuxer::write_timecodes2(FILE* fp,u_int64_t first_pts,u_int64_t last_pts,u_int32_t frame_num,u_int32_t frame_len)
{
    u_int64_t len=last_pts-first_pts;

    u_int64_t len2=frame_num*frame_len;

    if(len2>len || frame_len%90)
        write_timecodes(fp,first_pts,last_pts,frame_num,frame_len);
    else
    {
        u_int32_t frame_len_ms=frame_len/90;
        u_int32_t timecode_ms=base_pts/90;

        for(u_int32_t i=0;i<frame_num;i++)
        {
            fprintf(fp,"%u\n",timecode_ms);
            timecode_ms+=frame_len_ms;
        }
    }
}
#endif

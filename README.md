# XMediaPlayer -- Clone --
An iOS (Rudimentary) Player  (HLS Video ) from scratch without AVFoundation dependency :). Inspired by Exolayer (Android).
* An iOS (ObjC++) Player app & framwork.
* Only ABR (and SMART) with only Video rendering is currently supported.
  
   
1. To clone the project
  * git clone _this repo_   


Project can simply be imported in XCode (created with version 8).

That's it.

Enjoy :)

******************

# XMediaPalyer -- Introduction --

## XMediaPalyer: an iOS ABR Player
XMediaPalyer is an iOS ABR Player (iOS application) POC serving  to study the feasibility of implementing a player (open source or proprietary source without AVPlayer dependencies) on iOS. This version of playervsupports ABR with video H264 compressed and muxed within a &quot;.ts&quot; as HLS segment.

This achievement was possible thanks to a new evolution of the AVFoundation and VideoToolBox frameworks introduced by Apple since version 8.0 of iOS. Indeed, since this SDK version it was possible to use the embedded  H.264 H/W decoder to decode avc/video format and render it in a provided surface (CALayer).

Ok, well and good. However, from an open API to decode H.624 to an APB-Player.... There is a long way to go! but it is  possible.

So let&#39;s define which &quot;Player&quot; we would like to have with which capabilities.

Since this player had to serve (among other players on other platforms) to support the basic HLS_ABR capabilities.

Ok here we are, We need an ABR-Player that will do two main things:

#### 1- retrieve the data to present: _Data processing:_

1. Get the content&#39;s manifest and parse it (Extract format and playlists).
2. Manage ABR-segment cache and player buffer.
3. Demux segment (ts format) and extract pid of interest and use the appropriate frame consumer for each data stream/pid
4. Raise ABR metrics if available.

#### 2- Present a media content: _Media uncompression and rendering:_

1. Once media frames are extracted (such as H.264, AAC, AC3), the appropriate decoder and renderer are assigned to present the final media format (audio, video and text).
2. Some cosmetic (but user convenience) controls and view are provided (buffering indicator, player time-progress bar ....).

# 1. Data processing

1. _Get content description:_ The ABR content entry point is the master playlist (called also manifest) which defines the whole structure of media and provides the URLs of all parts of the media (description and stream content)  (see  [Adaptive bitrate streaming - Wikipedia](https://en.wikipedia.org/wiki/Adaptive_bitrate_streaming)  for more details). The application uses a third party component M3U8 parser ( [ M3U8 on GitHub](https://github.com/alexsun/M3U8Paser/tree/master/M3U8Kit) ) which was modified to expose hls segment interface. Once the playlists are parsed an internal data model is created and will serves to all application&#39;s components as required.
>Code ref#: XMediaPlayer/XPlayer/Third_Party/M3U8Parser/M3U8PlaylistModel.h


1. _Manage ABR-segments cache and player buffer_:  The ABR-Player core must ensure a sufficient player buffer (as possible) by caching number of segments to be consumed when it&#39;s a time to play them without waiting for. So the appropriate segment with a profile (bitrate) is selected depending on the platform current estimated bitrate. It is obvious that it starts with the lowest profile from the master playlist because it hasn&#39;t  yet any  estimated bandwidth (which is done during the download of the next segments). If the bitrate goes down until the download speed becomes less than the player&#39;s consumption speed then the consumption is hold (Player paused) until the cache is sufficiently provisioned. Let&#39;s schematise it:
 
``` 
>/* ABR-LOADER */
  While(Player_Is_Alive)
 {
 Buffer_Lenght = Last_Loaded_Segment.EndTime - Player.Position;
 if(Buffer_Lenght  ==0) Player.pause(cause = STALL);
else
   if(Player.isPaused(With_Cause == STALL)) Player.resume();
if(Buffer_Lenght &gt;= MIN_BUFFER_SIZE)continue;
 PlayList =SelectPlayList(Estimated_BandWith);
 Seg_Index_To_Load =Resolve_Next_Index(Buffer_Lenght ,PlayList);
 SegmentLoader.Load(PlayList,Seg_Index_To_Load);
}
 
Code ref#:XMediaPlayer/XPlayer/PlayerCore/hls/[AbrLoader.h, TrackSelector.h, SegmentLoader.h]
```

1._Demux segment:_ Sement is a part of stream described in the profile&#39;s playlist. It is formatted as ts (transport stream, see  [TS-Spec](https://fr.wikipedia.org/wiki/MPEG_Transport_Stream)) container so each media stream are transported  is elementary stream with a specific packet ID. The player core uses a third party ts demuxed ( [tsdemuxer on GitHub](https://github.com/clark15b/tsdemuxer)) which was modified to support AAC demuxing and adapted to be used with objc++. The core player framework provides a stream-reader factory that will instantiate to appropriate reader for an extracted ES packet based on this its stream type as bellow:


```
/*SEG-LOADER # LOAD SEGMENT*/
Seg_Url = Segment_To_Load.Url;
Seg_Data = Data_Soure.Load(Seg_Url);
PIDs=Ts_Demuxer.demux(Seg_Data);
for(PID pid in PIDs)
^Async_Do()
{
  Stream_Reader=Stream_Reader_Factory.getReaderFor(pid.Stream_Type);
  Stream_Consumer= Stream_Consumer_Factory.getConsumerFor(pid.Stream_Type);
  Stream_Reader.Read(pid, Stream_Consumer);
}

```



2._Raise ABR metrics: the ABR-Selector will apply the HLS segment selection algorithm and raise the metrics about its selections:

```
/*Segment-Selector Resolve_Next_Index (see Manage ABR-segments above )*/
Resolve_Next_Index(Buffer_Lenght ,PlayList)
{
 Index =Resolve_Standard(Buffer_Lenght ,PlayList);
 RequestedSegment =Get_Segment(CurrentProfile,Index);
 MaxProfileSegment=Get_Segment(MaxProfile,Index);
            Raise_Metrics([{"MaxProfile", MaxProfileSegment.bitrate},
                        {"RequestedProfile", RequestedSegment.bitrate},
                        {"Max.Segment";, RequestedSegment},
                        {"Requested.Segment",  RequestedSegment}]);
 return Index;
}

```



# 2. Media uncompression and rendering

Once the encoded media frames are extracted (as seen above) they are sent to the decoder to be decoded and presented ( in the provided surface in case of video frames). iOs SDK (especially VideoToolbox &amp; AVFoundation frameworks) provides two possible way to do it; the first one (the best an more complex one maybe) is to decode frame one by one using _VTDecompressionSessionCreate_  to create a decompression session which will bring up a decompressed frame through a callback then it needs, in case of video one, to be transformed from YUV to ARGB format to be displayable (such transformation could be done using OpenGL shader). Also a frame presentation time stamp should be managed. Let see now the second one which is  easy to use and so choosed for the POC.  This solution is base on a special CALayer  _AVSampleBufferDisplayLayer_ which provide an enqueuing mechanism allowing to send a well formatted buffer (header and presentation-time-stamp) to it and let it present the frame.

##### The advantages of the 1st solution : 
Gives a full control of buffer, so it possible to manage case of  DTS I-Frame.DTS &gt; B-Frame.DTS especially when a segment (.ts) starts with B-Frames instead of I-Frame.

##### The disadvantages:

- _Complex to implement:_
- Reordering frame potentially (according to fame PTS)
- Manage PTS/DTS and Clock (by soft).
- Will consume GPU bandwidth to convert formats.

##### The Advantages of the 2nd solution:

- Easy to implement
- Use optimised iOS platform format conversion.
- Works perfectly if Frames are well ordered :I-Frame -B-Frame.....

##### The disadvantages:

- Cannot handle correctly PTS and DTS that do not have the same order.
- No precise value of playing time-stamp.

>Code ref#:XMediaPlayer/XPlayer/PlayerUI/XPlayerLayer.h

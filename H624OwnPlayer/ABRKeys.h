//
//  SvqKeys.h
//  XMediaPlayer
//
//  Created by tyazid on 07/02/2017.
//  Copyright © 2017 tyazid. All rights reserved.
//

#ifndef SvqKeys_h
#define SvqKeys_h
/** KEY USED TO CONFIGURE XPLAYER SMART-ABR FEATURE (using Xplayer#setExtraConfiguration)
 Exp:
 [[self player] setExtraConfiguration:
 [NSDictionary dictionaryWithObjectsAndKeys:
 [NSNumber numberWithBool:YES],SVQAN_SMART_AVTIVATE_KEY,
 [NSNumber numberWithFloat:8.0f], SVQAN_NOTE_THRESHOLD_KEY,
 [NSNumber numberWithFloat:0.3f],SVQAN_DELTA_NOTE_KEY,
 nil]] ;
 **/


//FLOAT FRAC 0]..1]
#define BANDWIDTH_FRACTION @"abr.bandwidth.fraction"



/**  NOTIFICATION CENTER FOR SMART ABR   **/
#define SVQN_STAT_EVENT_NAME "abr.event.key"
#define NOTIFICATION_SMARTABR_CENTER_NAME  @"XplayertNotification.smart.abr.notification"
#endif /* SvqKeys_h */

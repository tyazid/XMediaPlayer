//
//  SettingViewController.h
//  XMediaPlayer
//
//  Created by tyazid on 10/02/2017.
//  Copyright © 2017 tyazid. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SettingViewController : UIViewController
@property (weak, nonatomic) IBOutlet UISlider *delatNoteSlide;
@property (weak, nonatomic) IBOutlet UILabel *deltaSlideLabel;
@property (weak, nonatomic) IBOutlet UISlider *thresholdSlide;
@property (weak, nonatomic) IBOutlet UILabel *thresholdSlideLabel;
@property (weak, nonatomic) IBOutlet UISlider *bandFractionSlide;
@property (weak, nonatomic) IBOutlet UILabel *bandFractionSlideLabel;


- (IBAction)deltaNoteSlideChange:(id)sender;

- (IBAction)thresholdSlideChange:(id)sender;

- (IBAction)bandwidthFractionChange:(id)sender;
- (IBAction)saveSetting:(id)sender;

@end

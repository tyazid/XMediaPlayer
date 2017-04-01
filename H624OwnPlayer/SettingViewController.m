//
//  SettingViewController.m
//  XMediaPlayer
//
//  Created by tyazid on 10/02/2017.
//  Copyright © 2017 tyazid. All rights reserved.
//

#import "SettingViewController.h"
#import "ABRKeys.h"
@interface SettingViewController ()

@end

@implementation SettingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    
    
    if([prefs valueForKey:BANDWIDTH_FRACTION])
        [[self bandFractionSlide] setValue: [((NSNumber*)[prefs valueForKey:BANDWIDTH_FRACTION]) floatValue]*100];
    
    [[self deltaSlideLabel]
     setText:[NSString stringWithFormat:@"%.02f",  [[self delatNoteSlide] value] ]];

    [[self thresholdSlideLabel]
     setText:[NSString stringWithFormat:@"%.02f%%",  [[self thresholdSlide] value] ]];

    
    [[self bandFractionSlideLabel]
     setText:[NSString stringWithFormat:@"%.02f%%",  [[self bandFractionSlide] value] ]];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
 
- (IBAction)deltaNoteSlideChange:(id)sender {
    
    [[self deltaSlideLabel]
    setText:[NSString stringWithFormat:@"%.02f",
                                    ((UISlider*)sender).value]];
}

- (IBAction)thresholdSlideChange:(id)sender {
   [[self thresholdSlideLabel] setText:[NSString stringWithFormat:@"%.02f%%",
                                  ((UISlider*)sender).value]];
}

- (IBAction)bandwidthFractionChange:(id)sender {
    [[self bandFractionSlideLabel] setText:[NSString stringWithFormat:@"%02d%%",
                                     (int)((UISlider*)sender).value]];
}

- (IBAction)saveSetting:(id)sender {
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    
        [prefs setObject:[NSNumber numberWithFloat: [[self bandFractionSlide] value]/100] forKey:BANDWIDTH_FRACTION];
    
}
@end

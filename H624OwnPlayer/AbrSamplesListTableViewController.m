//
//  AbrSamplesListTableViewController.m
//  XMediaPlayer
//
//  Created by tyazid on 06/02/2017.
//  Copyright © 2017 tyazid. All rights reserved.
//

#import "AbrSamplesListTableViewController.h"
#import "ViewController.h"
#import "AppSetting.h"
/*
@interface MyTableViewCell : UITableViewCell
@end

@implementation MyTableViewCell
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    // overwrite style
    self = [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifier];
    return self;
}
@end*/

@interface AbrSamplesListTableViewController ()

@end

@implementation AbrSamplesListTableViewController
NSArray*samples,*abrSupport;
NSArray*baseUrls;
NSArray*assets;

-(void) setSamples
{
    samples = [NSArray arrayWithObjects:@"BigBuckBunny",@"ARTE" ,@"Apple HLS",@"Sintel",nil];
    
    abrSupport = [NSArray arrayWithObjects:@"Smart-HLS",@"Smart-HLS" ,@"Standard-HLS",@"Standard-HLS",nil];

    
    baseUrls = [NSArray arrayWithObjects:
                @"http://184.72.239.149/vod/smil:BigBuckBunny.smil/",
                @"http://www.streambox.fr/playlists/test_001/",
                @"http://qthttp.apple.com.edgesuite.net/1010qwoeiuryfg/",
                @"https://bitdash-a.akamaihd.net/content/sintel/hls/",nil];
    
    assets = [NSArray arrayWithObjects:@"playlist.m3u8",
              @"stream.m3u8" , @"sl.m3u8",@"playlist.m3u8",nil];

}
-(void)setDefaults
{
    
    NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
    
    if(
        ![prefs valueForKey:BANDWIDTH_FRACTION] )
        
        
    {
         
         
        [prefs setObject:[NSNumber numberWithFloat: BANDW_FRACTION] forKey:BANDWIDTH_FRACTION];
    }
    
}
- (void)viewDidLoad {

 
    [super viewDidLoad];
    
    [self setDefaults];
    [self setSamples];
    
    
  }

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
     return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
     return [samples count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString * sampleTableId=@"SampleCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:sampleTableId];
    if(cell == Nil)
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:sampleTableId];
    cell.textLabel.text = [ samples objectAtIndex:indexPath.row];
    cell.detailTextLabel.text =[ abrSupport objectAtIndex:indexPath.row]; //abrSupport
    // Configure the cell...
    
    return cell;
}/*
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(nonnull NSIndexPath *)indexPath
{
    UIActionSheet *trackActionSheet =
    
    [[UIActionSheet alloc] initWithTitle:nil
                                delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil
                       otherButtonTitles:@"Play asset", nil];
    [trackActionSheet showInView:self.view];
    


}*/

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/


//#pragma mark - Navigation
//- (BOOL)shouldPerformSegueWithIdentifier:(NSString *)identifier sender:(id)sender {
//    NSLog(@" shouldPerformSegueWithIdentifier ");
/*
    
    if(!internal && [ identifier isEqualToString:@"assetDetails"]){
         UIActionSheet *trackActionSheet =
       
        [[UIActionSheet alloc] initWithTitle:nil
         delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil
         otherButtonTitles:@"Play asset", nil];
         [trackActionSheet showInView:self.view];
         
    }
    internal=NO;
    BOOL S = SEG;
    SEG= NO;
    return S;*/
    
//    return NO;
//}
BOOL SEG=NO;
BOOL internal = NO;
/*
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex{
    NSLog(@" OK PLAY %lu",buttonIndex);
    SEG=buttonIndex == 0;
    if(SEG){
   // internal=YES;
    NSIndexPath *indexPath =  [self.tableView indexPathForSelectedRow];
    [self.tableView selectRowAtIndexPath:indexPath
                                animated:YES
                          scrollPosition:UITableViewScrollPositionNone];
   //   [[self tableView] did]
   // [self.tableView
        
        
        
        
        NSString * storyboardName = @"Main";
        NSString * viewControllerID = @"PlayerView";
        UIStoryboard * storyboard = [UIStoryboard storyboardWithName:storyboardName bundle:nil];
        ViewController * controller = (ViewController *)[storyboard instantiateViewControllerWithIdentifier:viewControllerID];
        controller.asset = [assets objectAtIndex:indexPath.row];
        controller.baseUrl = [baseUrls objectAtIndex:indexPath.row];
        [self presentViewController:controller animated:YES completion:nil];
        
        
    }
    
    
    
}*/
// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    //assetDetails
    
    if([segue.identifier isEqualToString:@"assetDetails"]){
    
        
   /*
        UIActionSheet *trackActionSheet =
        [[UIActionSheet alloc] initWithTitle:nil
        delegate:self cancelButtonTitle:@"Cancel" destructiveButtonTitle:nil
        otherButtonTitles:@"Preview Track", nil];
        [trackActionSheet showInView:self.view];*/

        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        ViewController *destViewController = segue.destinationViewController;
        destViewController.asset = [assets objectAtIndex:indexPath.row];
        destViewController.baseUrl = [baseUrls objectAtIndex:indexPath.row];

        
    }
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    
}


@end

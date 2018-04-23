//
//  MainTableViewController.h
//  ATIS
//
//  Created by Eiichi Hayashi on 2018/04/22.
//  Copyright © 2018年 skyElements. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ATISTableViewCell.h"
#import "Downloader.h"

@interface MainTableViewController : UITableViewController <DownloaderDelegate>

@property (weak, nonatomic) IBOutlet UIBarButtonItem *editButton;
- (IBAction)editButton:(id)sender;
- (IBAction)refreshControl:(id)sender;

@end

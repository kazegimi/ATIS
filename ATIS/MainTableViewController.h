//
//  MainTableViewController.h
//  ATIS
//
//  Created by Eiichi Hayashi on 2018/04/22.
//  Copyright © 2018年 skyElements. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "ATISTableViewCell.h"
#import "ATISDownloader.h"
#import "TAFMETARTableViewController.h"

@interface MainTableViewController : UITableViewController <ATISDownloaderDelegate>

@property (weak, nonatomic) IBOutlet UIBarButtonItem *editButton;
- (IBAction)editButton:(id)sender;
@property (weak, nonatomic) IBOutlet UILabel *utcLabel;
- (IBAction)refreshControl:(id)sender;

@end

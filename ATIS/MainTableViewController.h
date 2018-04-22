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

- (IBAction)refreshControl:(id)sender;

@end

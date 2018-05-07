//
//  TAFMETARTableViewController.h
//  ATIS
//
//  Created by Eiichi Hayashi on 2018/05/05.
//  Copyright © 2018年 skyElements. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "TAFMETARTableViewCell.h"
#import "TAFMETARDownloader.h"

@interface TAFMETARTableViewController : UITableViewController <TAFMETARDownloaderDelegate>

@property (nonatomic) NSString *callsign;

- (IBAction)refreshControl:(id)sender;

@end

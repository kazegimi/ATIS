//
//  TAFMETARTableViewController.h
//  ATIS
//
//  Created by Eiichi Hayashi on 2018/05/05.
//  Copyright © 2018年 skyElements. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "TAFMETARTableViewCell.h"
#import "TAFDownloader.h"
#import "METARDownloader.h"

@interface TAFMETARTableViewController : UITableViewController <TAFDownloaderDelegate, METARDownloaderDelegate>

@property (nonatomic) NSString *callsign;
@property (weak, nonatomic) IBOutlet UILabel *utcLabel;

- (IBAction)refreshControl:(id)sender;

@end

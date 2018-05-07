//
//  TAFMETARTableViewCell.h
//  ATIS
//
//  Created by Eiichi Hayashi on 2018/05/07.
//  Copyright © 2018年 skyElements. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TAFMETARTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UILabel *tafMetarLabel;

@end

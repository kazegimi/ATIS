//
//  ATISTableViewCell.h
//  ATIS
//
//  Created by Eiichi Hayashi on 2018/04/22.
//  Copyright © 2018年 skyElements. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ATISTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *callsignLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (weak, nonatomic) IBOutlet UILabel *atisLabel;

@end

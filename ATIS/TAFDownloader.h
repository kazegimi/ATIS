//
//  TAFDownloader.h
//  ATIS
//
//  Created by Eiichi Hayashi on 2018/05/15.
//  Copyright © 2018年 skyElements. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol TAFDownloaderDelegate

@optional

- (void)didFinishDownloadingTAFWithData:(NSDictionary *)tafDictionary;
- (void)didFailDownloadingTAF;

@end

@interface TAFDownloader : NSObject <NSURLSessionDelegate>

@property (strong, nonatomic) id<TAFDownloaderDelegate> delegate;
@property (nonatomic) NSString *callsign;

- (void)startDownloadingTAF;

@end

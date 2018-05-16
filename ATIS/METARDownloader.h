//
//  METARDownloader.h
//  ATIS
//
//  Created by Eiichi Hayashi on 2018/05/15.
//  Copyright © 2018年 skyElements. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol METARDownloaderDelegate

@optional

- (void)didFinishDownloadingMETARWithData:(NSDictionary *)metarDictionary;
- (void)didFailDownloadingMETAR;

@end

@interface METARDownloader : NSObject <NSURLSessionDelegate>

@property (strong, nonatomic) id<METARDownloaderDelegate> delegate;
@property (nonatomic) NSString *callsign;

- (void)startDownloadingMETAR;

@end

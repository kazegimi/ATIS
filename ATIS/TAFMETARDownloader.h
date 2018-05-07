//
//  TAFMETARDownloader.h
//  ATIS
//
//  Created by Eiichi Hayashi on 2018/05/07.
//  Copyright © 2018年 skyElements. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol TAFMETARDownloaderDelegate

@optional

- (void)didFinishDownloadingTAFMETARWithData:(NSDictionary *)tafMetarDictionary;
- (void)didFailDownloadingTAFMETAR;

@end

@interface TAFMETARDownloader : NSObject <NSURLSessionDelegate>

@property (strong, nonatomic) id<TAFMETARDownloaderDelegate> delegate;
@property (nonatomic) NSString *callsign;

- (void)startDownloadingTAFMETAR;

@end


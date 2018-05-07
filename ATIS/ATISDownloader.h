//
//  ATISDownloader.h
//  ATIS
//
//  Created by Eiichi Hayashi on 2018/05/07.
//  Copyright © 2018年 skyElements. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ATISDownloaderDelegate

@optional

- (void)didFinishDownloadingATISWithData:(NSData *)data;
- (void)didFailDownloadingATIS;

@end

@interface ATISDownloader : NSObject <NSURLSessionDelegate>

@property (strong, nonatomic) id<ATISDownloaderDelegate> delegate;

- (void)startDownloadingATIS;

@end

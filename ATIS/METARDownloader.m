//
//  METARDownloader.m
//  ATIS
//
//  Created by Eiichi Hayashi on 2018/05/15.
//  Copyright © 2018年 skyElements. All rights reserved.
//

#import "METARDownloader.h"

@implementation METARDownloader {
    NSMutableData *mutableData;
    NSMutableDictionary *metarDictionary;
}

- (void)startDownloadingMETAR {
    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfiguration
                                                          delegate:self
                                                     delegateQueue:[NSOperationQueue mainQueue]];
    
    NSString *urlString = [NSString stringWithFormat:@"https://api.checkwx.com/metar/%@/decoded", _callsign];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]
                                                           cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                       timeoutInterval:10.0];
    [request setValue:@"51bf61c7bfe69a95a1995e9957" forHTTPHeaderField:@"X-API-Key"];
    
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request];
    
    mutableData = [[NSMutableData alloc] init];
    metarDictionary = [NSMutableDictionary new];
    
    [task resume];
}

// レスポンス受信時の処理
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition disposition))completionHandler {
    completionHandler(NSURLSessionResponseAllow);// どのレスポンスが来ても通信を継続
}

// データを受信時の処理
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    [mutableData appendData:data];
}

// 通信完了、または失敗時の処理
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    if (!error) {
        // 成功時の処理
        NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:mutableData options:kNilOptions error:nil];
        NSDictionary *dataDictionary = dictionary[@"data"][0];
        NSLog(@"%@", dataDictionary);
        // "**** TAF/METAR Currently Unavailable"の場合、NSStringが返ってくる
        NSString *className = NSStringFromClass([dataDictionary class]);
        NSString *rawText = @"";
        if ([className isEqualToString:@"__NSCFString"]) {
            [self.delegate didFailDownloadingMETAR];
            return;
        } else {
            rawText = dataDictionary[@"raw_text"];
        }
        
        // 改行の挿入
        rawText = [rawText stringByReplacingOccurrencesOfString:@"TAF " withString:@""];
        rawText = [rawText stringByReplacingOccurrencesOfString:@"BECMG" withString:@"\n  BECMG"];
        rawText = [rawText stringByReplacingOccurrencesOfString:@"TEMPO" withString:@"\n  TEMPO"];
        rawText = [rawText stringByReplacingOccurrencesOfString:@"RMK" withString:@"\n  RMK"];
        
        [metarDictionary setObject:rawText forKey:@"metar"];
        [metarDictionary setObject:dataDictionary[@"observed"] forKey:@"metar_observed"];
        
        [self.delegate didFinishDownloadingMETARWithData:metarDictionary];
    } else {
        // 失敗時の処理
        [self.delegate didFailDownloadingMETAR];
    }
    [session invalidateAndCancel];
}

@end

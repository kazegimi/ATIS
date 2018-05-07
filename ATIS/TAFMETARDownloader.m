//
//  TAFMETARDownloader.m
//  ATIS
//
//  Created by Eiichi Hayashi on 2018/05/07.
//  Copyright © 2018年 skyElements. All rights reserved.
//

#import "TAFMETARDownloader.h"

@implementation TAFMETARDownloader {
    NSInteger sequence;
    NSMutableData *mutableData;
    NSMutableDictionary *tafMetarDictionary;
}

- (void)startDownloadingTAFMETAR {
    tafMetarDictionary = [NSMutableDictionary new];
    [self startDownloadingTAF];
}

- (void)startDownloadingTAF {
    sequence = 0;
    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfiguration
                                                          delegate:self
                                                     delegateQueue:[NSOperationQueue mainQueue]];
    
    NSString *urlString = [NSString stringWithFormat:@"https://api.checkwx.com/taf/%@", _callsign];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]
                                                           cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                       timeoutInterval:10.0];
    [request setValue:@"51bf61c7bfe69a95a1995e9957" forHTTPHeaderField:@"X-API-Key"];
    
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request];
    
    mutableData = [[NSMutableData alloc] init];
    
    [task resume];
}

- (void)startDownloadingMETAR {
    sequence = 1;
    NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:sessionConfiguration
                                                          delegate:self
                                                     delegateQueue:[NSOperationQueue mainQueue]];
    
    NSString *urlString = [NSString stringWithFormat:@"https://api.checkwx.com/metar/%@", _callsign];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlString]
                                                           cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                       timeoutInterval:10.0];
    [request setValue:@"51bf61c7bfe69a95a1995e9957" forHTTPHeaderField:@"X-API-Key"];
    
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request];
    
    mutableData = [[NSMutableData alloc] init];
    
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
        NSString *string = dictionary[@"data"][0];
        
        if (!string) {
            [self.delegate didFailDownloadingTAFMETAR];
            return;
        }
        
        // 改行の挿入
        string = [string stringByReplacingOccurrencesOfString:@"BECMG" withString:@"\nBECMG"];
        string = [string stringByReplacingOccurrencesOfString:@"TEMPO" withString:@"\nTEMPO"];
        string = [string stringByReplacingOccurrencesOfString:@"RMK" withString:@"\nRMK"];
        
        switch (sequence) {
            case 0:
                [tafMetarDictionary setObject:string forKey:@"taf"];
                [self startDownloadingMETAR];
                break;
                
            case 1:
                [tafMetarDictionary setObject:string forKey:@"metar"];
                [self didFinishDownloading];
                break;
                
            default:
                break;
        }
    } else {
        // 失敗時の処理
        [self.delegate didFailDownloadingTAFMETAR];
    }
    [session invalidateAndCancel];
}

- (void)didFinishDownloading {
    [self.delegate didFinishDownloadingTAFMETARWithData:tafMetarDictionary];
}

@end

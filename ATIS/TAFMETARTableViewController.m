//
//  TAFMETARTableViewController.m
//  ATIS
//
//  Created by Eiichi Hayashi on 2018/05/05.
//  Copyright © 2018年 skyElements. All rights reserved.
//

#import "TAFMETARTableViewController.h"
#import "AppDelegate.h"

@interface TAFMETARTableViewController ()

@end

@implementation TAFMETARTableViewController {
    NSTimer *timer;
    // CoreData用
    AppDelegate *appDelegate;
    NSManagedObjectContext *context;
    
    TAFDownloader *tafDownloader;
    METARDownloader *metarDownloader;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    timer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                             target:self
                                           selector:@selector(timer:)
                                           userInfo:nil
                                            repeats:YES];
    
    // CoreDataの準備
    appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    context = appDelegate.persistentContainer.viewContext;
    
    self.title = _callsign;
    
    tafDownloader = [[TAFDownloader alloc] init];
    tafDownloader.delegate = self;
    tafDownloader.callsign = _callsign;
    
    metarDownloader = [[METARDownloader alloc] init];
    metarDownloader.delegate = self;
    metarDownloader.callsign = _callsign;
}

- (void)viewWillAppear:(BOOL)animated {
    [self showUTC];
}

- (void)timer:(NSTimer *)timer {
    [self showUTC];
}

- (void)showUTC {
    // UTC表示
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"dd HH:mm"];
    [formatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    NSString *utcString = [formatter stringFromDate:[NSDate date]];
    _utcLabel.text = [NSString stringWithFormat:@"%@Z", utcString];
}

- (IBAction)refreshControl:(id)sender {
    [tafDownloader startDownloadingTAF];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    switch (section) {
        case 0:
            return @"TAF";
            break;
            
        case 1:
            return @"METAR";
            break;
            
        default:
            return @"";
            break;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    TAFMETARTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    
    cell.timeLabel.text = @"NO DATA";
    cell.tafMetarLabel.text = @"NO DATA";
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Airport"];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Airport" inManagedObjectContext:context];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"callsign like %@", _callsign];
    [request setEntity:entity];
    [request setPredicate:predicate];
    NSArray *result = [context executeFetchRequest:request error:nil];
    if (result.count != 0) {
        NSString *dateString;
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"dd-MM-yyyy @ HH:mmZ"];
        [formatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
        NSDate *date;
        switch (indexPath.section) {
            case 0:{
                cell.tafMetarLabel.text = [result[0] valueForKey:@"taf"];
                // 時間計算
                dateString = [result[0] valueForKey:@"taf_issued"];
                date = [formatter dateFromString:dateString];
                NSMutableString *timeText = [NSMutableString new];
                if (date) {
                    float interval = [date timeIntervalSinceNow];
                    NSInteger minutes = (NSInteger)fabsf(interval / 60.0f);
                    if (minutes < 60) {
                        [timeText appendString:[NSString stringWithFormat:@"(発行%ld分前)", minutes]];
                    } else {
                        NSInteger hours = (NSInteger)roundf(minutes / 60.0f);
                        if (hours > 99) {
                            [timeText appendString:@"(発行99時間以上前)"];
                        } else {
                            [timeText appendString:[NSString stringWithFormat:@"(発行%ld時間前)", hours]];
                        }
                    }
                }
                
                dateString = [result[0] valueForKey:@"taf_valid_from"];
                NSDate *dateFrom = [formatter dateFromString:dateString];
                dateString = [result[0] valueForKey:@"taf_valid_to"];
                NSDate *dateTo = [formatter dateFromString:dateString];
                if (dateFrom && dateTo) {
                    NSComparisonResult resultFrom = [[NSDate date] compare:dateFrom];
                    NSComparisonResult resultTo = [[NSDate date] compare:dateTo];
                    if (resultFrom == NSOrderedAscending || resultTo == NSOrderedDescending) {
                        NSString *string = @"";
                        if(resultFrom == NSOrderedAscending) {
                            float intervalFrom = [dateFrom timeIntervalSinceNow];
                            NSInteger minutesFrom = (NSInteger)fabsf(intervalFrom / 60.0f);
                            if (minutesFrom < 60) {
                                string = [NSString stringWithFormat:@" 範囲外(%ld分後から有効)", minutesFrom];
                            } else {
                                NSInteger hoursFrom = (NSInteger)roundf(minutesFrom / 60.0f);
                                if (hoursFrom > 99) {
                                    string = @" 範囲外(99時間以上後から有効)";
                                } else {
                                    string = [NSString stringWithFormat:@" 範囲外(%ld時間後から有効)", hoursFrom];
                                }
                            }
                            [timeText appendString:string];
                        } else {
                            float intervalTo = [dateTo timeIntervalSinceNow];
                            NSInteger minutesTo = (NSInteger)fabsf(intervalTo / 60.0f);
                            if (minutesTo < 60) {
                                string = [NSString stringWithFormat:@" 範囲外(%ld分前に終了)", minutesTo];
                            } else {
                                NSInteger hoursTo = (NSInteger)roundf(minutesTo / 60.0f);
                                if (hoursTo > 99) {
                                    string = @" 範囲外(99時間以上前に終了)";
                                } else {
                                    string = [NSString stringWithFormat:@" 範囲外(%ld時間前に終了)", hoursTo];
                                }
                            }
                            [timeText appendString:string];
                        }
                    } else {
                        float intervalFrom = [dateFrom timeIntervalSinceNow];
                        NSInteger minutesFrom = (NSInteger)fabsf(intervalFrom / 60.0f);
                        if (minutesFrom < 60) {
                            [timeText appendString:[NSString stringWithFormat:@" %ld分前から", minutesFrom]];
                        } else {
                            NSInteger hoursFrom = (NSInteger)roundf(minutesFrom / 60.0f);
                            [timeText appendString:[NSString stringWithFormat:@" %ld時間前から", hoursFrom]];
                        }
                        float intervalTo = [dateTo timeIntervalSinceNow];
                        NSInteger minutesTo = (NSInteger)fabsf(intervalTo / 60.0f);
                        if (minutesTo < 60) {
                            [timeText appendString:[NSString stringWithFormat:@"%ld分後まで", minutesTo]];
                        } else {
                            NSInteger hoursTo = (NSInteger)roundf(minutesTo / 60.0f);
                            [timeText appendString:[NSString stringWithFormat:@"%ld時間後まで", hoursTo]];
                        }
                    }
                }
                if (![timeText isEqualToString:@""]) cell.timeLabel.text = timeText;
                
                break;
            }
                
            case 1:{
                cell.tafMetarLabel.text = [result[0] valueForKey:@"metar"];
                // 時間計算
                dateString = [result[0] valueForKey:@"metar_observed"];
                date = [formatter dateFromString:dateString];
                if (date) {
                    float interval = [date timeIntervalSinceNow];
                    NSInteger minutes = (NSInteger)fabsf(interval / 60.0f);
                    if (minutes > 999) {
                        cell.timeLabel.text = @"999分以上前";
                    } else {
                        cell.timeLabel.text = [NSString stringWithFormat:@"%ld分前", minutes];
                    }
                }
                break;
            }
                
            default:{
                break;
            }
        }
    }
    return cell;
}

- (void)didFinishDownloadingTAFWithData:(NSDictionary *)tafDictionary {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Airport"];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Airport" inManagedObjectContext:context];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"callsign like %@", _callsign];
    [request setEntity:entity];
    [request setPredicate:predicate];
    NSArray *result = [context executeFetchRequest:request error:nil];
    if (result.count != 0) {
        NSManagedObject *airport = result[0];
        [airport setValue:tafDictionary[@"taf"] forKey:@"taf"];
        [airport setValue:tafDictionary[@"taf_valid_from"] forKey:@"taf_valid_from"];
        [airport setValue:tafDictionary[@"taf_valid_to"] forKey:@"taf_valid_to"];
        [airport setValue:tafDictionary[@"taf_issued"] forKey:@"taf_issued"];
        [appDelegate saveContext];
    }
    
    [self.tableView reloadData];
    [metarDownloader startDownloadingMETAR];
}

- (void)didFinishDownloadingMETARWithData:(NSDictionary *)metarDictionary {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Airport"];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Airport" inManagedObjectContext:context];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"callsign like %@", _callsign];
    [request setEntity:entity];
    [request setPredicate:predicate];
    NSArray *result = [context executeFetchRequest:request error:nil];
    if (result.count != 0) {
        NSManagedObject *airport = result[0];
        [airport setValue:metarDictionary[@"metar"] forKey:@"metar"];
        [airport setValue:metarDictionary[@"metar_observed"] forKey:@"metar_observed"];
        [appDelegate saveContext];
    }
    
    [self.tableView reloadData];
    [self.refreshControl endRefreshing];
}

- (void)didFailDownloadingTAF {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Failed Downloading TAF" message:@"Check your internet connection." preferredStyle:UIAlertControllerStyleAlert];
    
    [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self.refreshControl endRefreshing];
    }]];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)didFailDownloadingMETAR {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Failed Downloading METAR" message:@"Check your internet connection." preferredStyle:UIAlertControllerStyleAlert];
    
    [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self.refreshControl endRefreshing];
    }]];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

@end

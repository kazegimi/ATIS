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
    AppDelegate *appDelegate;
    NSManagedObjectContext *context;
    
    TAFMETARDownloader *tafMetarDownloader;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // CoreDataの準備
    appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    context = appDelegate.persistentContainer.viewContext;
    
    self.title = _callsign;
    
    tafMetarDownloader = [[TAFMETARDownloader alloc] init];
    tafMetarDownloader.delegate = self;
    tafMetarDownloader.callsign = _callsign;
}

- (void)viewWillAppear:(BOOL)animated {
    // UTC表示
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"HH:mm"];
    [formatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    NSString *utcString = [formatter stringFromDate:[NSDate date]];
    _utcLabel.text = [NSString stringWithFormat:@"%@Z", utcString];
}

- (IBAction)refreshControl:(id)sender {
    [tafMetarDownloader startDownloadingTAFMETAR];
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
                        [timeText appendString:[NSString stringWithFormat:@"%ld分前発行", minutes]];
                    } else {
                        NSInteger hours = (NSInteger)roundf(minutes / 60.0f);
                        if (hours > 99) hours = 99;
                        [timeText appendString:[NSString stringWithFormat:@"%ld時間前発行", hours]];
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
                                if (hoursFrom > 99) hoursFrom = 99;
                                string = [NSString stringWithFormat:@" 範囲外(%ld時間後から有効)", hoursFrom];
                            }
                            [timeText appendString:string];
                        } else {
                            float intervalTo = [dateTo timeIntervalSinceNow];
                            NSInteger minutesTo = (NSInteger)fabsf(intervalTo / 60.0f);
                            if (minutesTo < 60) {
                                string = [NSString stringWithFormat:@" 範囲外(%ld分前に終了)", minutesTo];
                            } else {
                                NSInteger hoursTo = (NSInteger)roundf(minutesTo / 60.0f);
                                if (hoursTo > 99) hoursTo = 99;
                                string = [NSString stringWithFormat:@" 範囲外(%ld時間前に終了)", hoursTo];
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
                    if (minutes > 999) minutes = 999;
                    cell.timeLabel.text = [NSString stringWithFormat:@"%ld分前", minutes];
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

- (void)didFinishDownloadingTAFMETARWithData:(NSDictionary *)tafMetarDictionary {
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Airport"];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Airport" inManagedObjectContext:context];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"callsign like %@", _callsign];
    [request setEntity:entity];
    [request setPredicate:predicate];
    NSArray *result = [context executeFetchRequest:request error:nil];
    if (result.count != 0) {
        NSManagedObject *airport = result[0];
        [airport setValue:tafMetarDictionary[@"taf"] forKey:@"taf"];
        [airport setValue:tafMetarDictionary[@"taf_valid_from"] forKey:@"taf_valid_from"];
        [airport setValue:tafMetarDictionary[@"taf_valid_to"] forKey:@"taf_valid_to"];
        [airport setValue:tafMetarDictionary[@"taf_issued"] forKey:@"taf_issued"];
        [airport setValue:tafMetarDictionary[@"metar"] forKey:@"metar"];
        [airport setValue:tafMetarDictionary[@"metar_observed"] forKey:@"metar_observed"];
        [appDelegate saveContext];
    }
    
    [self.tableView reloadData];
    [self.refreshControl endRefreshing];
}

- (void)didFailDownloadingTAFMETAR {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Failed Downloading" message:@"Check your internet connection." preferredStyle:UIAlertControllerStyleAlert];
    
    [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self.refreshControl endRefreshing];
    }]];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

@end

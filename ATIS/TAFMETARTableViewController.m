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
            case 0:
                cell.tafMetarLabel.text = [result[0] valueForKey:@"taf"];
                // 時間計算
                dateString = [result[0] valueForKey:@"taf_valid_to"];
                date = [formatter dateFromString:dateString];
                if (date) {
                    NSComparisonResult result = [[NSDate date] compare:date];
                    if (result == NSOrderedSame || result == NSOrderedAscending) {
                        cell.timeLabel.text = @"有効";
                    } else {
                        float interval = [date timeIntervalSinceNow];
                        NSInteger minutes = (NSInteger)fabsf((interval / 60.0f));
                        if (minutes > 999) minutes = 999;
                        cell.timeLabel.text = [NSString stringWithFormat:@"%ld分前", minutes];
                    }
                } else {
                    cell.timeLabel.text = @"NO DATA";
                }
                break;
                
            case 1:
                cell.tafMetarLabel.text = [result[0] valueForKey:@"metar"];
                // 時間計算
                dateString = [result[0] valueForKey:@"metar_observed"];
                date = [formatter dateFromString:dateString];
                if (date) {
                    float interval = [date timeIntervalSinceNow];
                    NSInteger minutes = (NSInteger)fabsf((interval / 60.0f));
                    if (minutes > 999) minutes = 999;
                    cell.timeLabel.text = [NSString stringWithFormat:@"%ld分前", minutes];
                } else {
                    cell.timeLabel.text = @"NO DATA";
                }
                break;
                
            default:
                break;
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
        [airport setValue:tafMetarDictionary[@"taf_valid_to"] forKey:@"taf_valid_to"];
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

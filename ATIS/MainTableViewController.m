//
//  MainTableViewController.m
//  ATIS
//
//  Created by Eiichi Hayashi on 2018/04/22.
//  Copyright © 2018年 skyElements. All rights reserved.
//

#import "MainTableViewController.h"

@interface MainTableViewController ()

@end

@implementation MainTableViewController {
    NSArray *airportsArray;
    NSArray *ordersArray;
    Downloader *downloader;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // NSUserDefaultの初期化
    NSMutableDictionary *keyValues = [NSMutableDictionary dictionary];
    [keyValues setObject:@[] forKey:@"airportsArray"];
    NSString *path = [[NSBundle mainBundle] pathForResource:@"default" ofType:@"json"];
    NSData *data = [NSData dataWithContentsOfFile:path];
    NSArray *defaultOrdersArray = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
    [keyValues setObject:defaultOrdersArray forKey:@"ordersArray"];
    [[NSUserDefaults standardUserDefaults] registerDefaults:keyValues];
    
    downloader = [[Downloader alloc] init];
    downloader.delegate = self;
    
    [self reload];
}

- (void)viewWillAppear:(BOOL)animated {
    [self reload];
}

- (void)reload {
    airportsArray = [[NSUserDefaults standardUserDefaults] objectForKey:@"airportsArray"];
    ordersArray = [[NSUserDefaults standardUserDefaults] objectForKey:@"ordersArray"];
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return ordersArray.count;
}

/*
- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    if([view isKindOfClass:[UITableViewHeaderFooterView class]]){
        UITableViewHeaderFooterView *tableViewHeaderFooterView = (UITableViewHeaderFooterView *) view;
        tableViewHeaderFooterView.textLabel.font = [UIFont boldSystemFontOfSize:17.0f];
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return ordersArray[section];
}
 */

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ATISTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    
    NSString *callsign = ordersArray[indexPath.section];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"callsign like %@", callsign];
    NSDictionary *airportDictionary = [[airportsArray filteredArrayUsingPredicate:predicate] firstObject];
    
    // 時間計算
    NSString *dateString = airportDictionary[@"atistime"];
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"yyyyMMddHHmm"];
    [formatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
    NSDate *atisDate = [formatter dateFromString:dateString];
    float interval = [atisDate timeIntervalSinceNow];
    
    cell.callsignLabel.text = ordersArray[indexPath.section];
    cell.timeLabel.text = [NSString stringWithFormat:@"%ld分前", (NSInteger)fabsf((interval / 60.0f))];
    cell.atisLabel.text = airportDictionary[@"atisdat"];
    
    return cell;
}
/*
- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleNone;
}

- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
    [orderArray exchangeObjectAtIndex:toIndexPath.row withObjectAtIndex:fromIndexPath.row];
}
 */

- (IBAction)refreshControl:(id)sender {
    [downloader startDownloading];
}

- (void)didFinishDownloadingWithData:(NSData *)data {
    airportsArray = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
    
    [[NSUserDefaults standardUserDefaults] setObject:airportsArray forKey:@"airportsArray"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [self.tableView reloadData];
    
    [self.refreshControl endRefreshing];
}

- (void)didFailDownloading {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Failed Downloading" message:@"Check your internet connection." preferredStyle:UIAlertControllerStyleAlert];
    
    [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self.refreshControl endRefreshing];
    }]];
    
    [self presentViewController:alertController animated:YES completion:nil];
}
    
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

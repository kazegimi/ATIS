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
    NSMutableArray *ordersArray;
    Downloader *downloader;
    BOOL isEditing;
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
    
    isEditing = NO;
    
    [self reload];
}

- (void)viewWillAppear:(BOOL)animated {
    [self reload];
}

- (void)reload {
    NSData *airportsArrayData = [[NSUserDefaults standardUserDefaults] objectForKey:@"airportsArrayData"];
    airportsArray = [NSJSONSerialization JSONObjectWithData:airportsArrayData options:kNilOptions error:nil];
    ordersArray = [NSMutableArray new];
    ordersArray = [NSMutableArray arrayWithArray:[[NSUserDefaults standardUserDefaults] objectForKey:@"ordersArray"]];
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
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
    return ordersArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ATISTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    
    NSString *callsign = ordersArray[indexPath.row];
    cell.callsignLabel.text = ordersArray[indexPath.row];
    cell.timeLabel.text = @"NO DATA";
    cell.atisLabel.text = @"NO DATA";
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"callsign like %@", callsign];
    NSDictionary *airportDictionary = [[airportsArray filteredArrayUsingPredicate:predicate] firstObject];
    if (airportDictionary.count != 0) {
        // 時間計算
        NSString *dateString = airportDictionary[@"atistime"];
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyyMMddHHmm"];
        [formatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
        NSDate *atisDate = [formatter dateFromString:dateString];
        if (atisDate) {
            float interval = [atisDate timeIntervalSinceNow];
            NSInteger minutes = (NSInteger)fabsf((interval / 60.0f));
            if (minutes > 999) minutes = 999;
            cell.timeLabel.text = [NSString stringWithFormat:@"%ld分前", minutes];
        } else {
            cell.timeLabel.text = @"";
        }
        
        cell.atisLabel.text = airportDictionary[@"atisdat"];
    }
    
    return cell;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleNone;
}

- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
    [ordersArray exchangeObjectAtIndex:toIndexPath.row withObjectAtIndex:fromIndexPath.row];
    [[NSUserDefaults standardUserDefaults] setObject:ordersArray forKey:@"ordersArray"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (IBAction)editButton:(id)sender {
    isEditing = !isEditing;
    [self.tableView setEditing:isEditing animated:YES];
    if (isEditing) {
        [_editButton setTitle:@"完了"];
    } else {
        [_editButton setTitle:@"並べ替え"];
    }
}

- (IBAction)refreshControl:(id)sender {
    [downloader startDownloading];
}

- (void)didFinishDownloadingWithData:(NSData *)data {
    [[NSUserDefaults standardUserDefaults] setObject:data forKey:@"airportsArrayData"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    airportsArray = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
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

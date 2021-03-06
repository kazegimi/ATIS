//
//  MainTableViewController.m
//  ATIS
//
//  Created by Eiichi Hayashi on 2018/04/22.
//  Copyright © 2018年 skyElements. All rights reserved.
//

#import "MainTableViewController.h"
// CoreData用
#import "AppDelegate.h"

@interface MainTableViewController ()

@property (strong, nonatomic) NSManagedObjectContext *conext;

@end

@implementation MainTableViewController {
    NSTimer *timer;
    // CoreData用
    AppDelegate *appDelegate;
    NSManagedObjectContext *context;

    NSMutableOrderedSet *ordersSet;
    ATISDownloader *atisDownloader;
    BOOL isEditing;
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
    
    /*
    // データ取得
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Airport"];
    NSArray *results = [context executeFetchRequest:request error:nil];
     */
    
    /*
    // データの挿入
    NSManagedObject *airport = [NSEntityDescription insertNewObjectForEntityForName:@"Airport" inManagedObjectContext:context];
    [airport setValue:defaultOrdersArray[i] forKey:@"callsign"];
     [appDelegate saveContext];
     */
    
    /*
    // 全データ削除
    for (NSManagedObject *managedObject in results) {
        [context deleteObject:managedObject];
    }
    [appDelegate saveContext];
     */
    
    /*
    // データ検索
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Airport"];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Airport" inManagedObjectContext:context];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"callsign like %@", @"RJAA"];
    [request setEntity:entity];
    [request setPredicate:predicate];
    NSArray *results = [context executeFetchRequest:request error:nil];
     */
    
    /*
    // データ削除
    for (NSManagedObject *managedObject in results) {
        [context deleteObject:managedObject];
    }
    [appDelegate saveContext];
     */
    
    // URLの取得
    NSURL *url = [NSURL URLWithString:@"http://skyelements.jp/app/ATIS/url.txt"];
    NSData *data = [NSData dataWithContentsOfURL:url];
    NSString *urlString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    [[NSUserDefaults standardUserDefaults] setObject:urlString forKey:@"urlString"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    ordersSet = [NSMutableOrderedSet new];
    
    atisDownloader = [[ATISDownloader alloc] init];
    atisDownloader.delegate = self;
    
    isEditing = NO;
    
    [self reload];
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

- (void)reload {
    ordersSet = [NSMutableOrderedSet orderedSetWithArray:[[NSUserDefaults standardUserDefaults] objectForKey:@"ordersArray"]];
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
 */

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (ordersSet.count == 0) {
        return nil;
    } else {
        return @"ATIS";
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    if (ordersSet.count == 0) {
        UIImageView *headerImageView = [[UIImageView alloc] init];
        headerImageView.contentMode = UIViewContentModeScaleAspectFit;
        //headerImageView.backgroundColor = [UIColor redColor];
        headerImageView.image = [UIImage imageNamed:@"swipe.png"];
        return headerImageView;
    } else {
        return nil;
    }
}

/*
- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    return @"";
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(nonnull UIView *)view forSection:(NSInteger)section {
    UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
    header.textLabel.numberOfLines = 0;
    if (ordersSet.count == 0) {
        header.textLabel.textAlignment = NSTextAlignmentCenter;
    } else {
        header.textLabel.textAlignment = NSTextAlignmentLeft;
    }
}
 */

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return ordersSet.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    ATISTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    
    NSString *callsign = ordersSet[indexPath.row];
    cell.callsignLabel.text = ordersSet[indexPath.row];
    cell.timeLabel.text = @"NO DATA";
    cell.atisLabel.text = @"NO DATA";
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Airport"];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Airport" inManagedObjectContext:context];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"callsign like %@", callsign];
    [request setEntity:entity];
    [request setPredicate:predicate];
    NSArray *result = [context executeFetchRequest:request error:nil];
    if (result.count != 0) {
        if (![[result[0] valueForKey:@"atisdat"] isEqualToString:@""]) {
            // 時間計算
            if (![[result[0] valueForKey:@"atistime"] isEqualToString:@""]) {
                NSString *dateString = [result[0] valueForKey:@"atistime"];
                NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                [formatter setDateFormat:@"yyyyMMddHHmm"];
                [formatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
                NSDate *atisDate = [formatter dateFromString:dateString];
                if (atisDate) {
                    float interval = [atisDate timeIntervalSinceNow];
                    NSInteger minutes = (NSInteger)fabsf(interval / 60.0f);
                    if (minutes > 999) {
                        cell.timeLabel.text = @"999分以上前";
                    } else {
                        cell.timeLabel.text = [NSString stringWithFormat:@"%ld分前", minutes];
                    }
                }
                cell.atisLabel.text = [result[0] valueForKey:@"atisdat"];
            }
        }
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleNone;
}

- (BOOL)tableView:(UITableView *)tableView shouldIndentWhileEditingRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
    id object = [ordersSet objectAtIndex:fromIndexPath.row];
    [ordersSet removeObjectAtIndex:fromIndexPath.row];
    [ordersSet insertObject:object atIndex:toIndexPath.row];
    [[NSUserDefaults standardUserDefaults] setObject:[ordersSet array] forKey:@"ordersArray"];
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
    [atisDownloader startDownloadingATIS];
}

- (void)didFinishDownloadingATISWithData:(NSData *)data {
    NSArray *atisArray = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
    NSLog(@"%@", atisArray);
    for (NSDictionary *atis in atisArray) {
        NSString *callsign = atis[@"callsign"];
        [ordersSet addObject:callsign];
        [[NSUserDefaults standardUserDefaults] setObject:[ordersSet array] forKey:@"ordersArray"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Airport"];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"Airport" inManagedObjectContext:context];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"callsign like %@", callsign];
        [request setEntity:entity];
        [request setPredicate:predicate];
        NSArray *result = [context executeFetchRequest:request error:nil];
        NSManagedObject *airport;
        if (result.count == 0) {
            airport = [NSEntityDescription insertNewObjectForEntityForName:@"Airport" inManagedObjectContext:context];
        } else {
            airport = result[0];
        }
        [airport setValue:atis[@"callsign"] forKey:@"callsign"];
        if (![atis[@"atistime"] isEqual:[NSNull null]]) {
            [airport setValue:atis[@"atistime"] forKey:@"atistime"];
        } else {
            [airport setValue:@"" forKey:@"atistime"];
        }
        [airport setValue:atis[@"atisdat"] forKey:@"atisdat"];
        [appDelegate saveContext];
    }
    [self reload];
    [self.refreshControl endRefreshing];
}

- (void)didFailDownloadingATIS {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"Failed Downloading" message:@"Check your internet connection." preferredStyle:UIAlertControllerStyleAlert];
    
    [alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self.refreshControl endRefreshing];
    }]];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"TAFMETARSegue"]) {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        TAFMETARTableViewController *tafMetarTableViewController = segue.destinationViewController;
        tafMetarTableViewController.callsign = ordersSet[indexPath.row];
    }
}
    
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end

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
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:@"Airport"];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Airport" inManagedObjectContext:context];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"callsign like %@", _callsign];
    [request setEntity:entity];
    [request setPredicate:predicate];
    NSArray *result = [context executeFetchRequest:request error:nil];
    if (result.count != 0) {
        cell.textLabel.numberOfLines = 0;
        switch (indexPath.section) {
            case 0:
                cell.textLabel.text = [result[0] valueForKey:@"taf"];
                break;
                
            case 1:
                cell.textLabel.text = [result[0] valueForKey:@"metar"];
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
        [airport setValue:tafMetarDictionary[@"metar"] forKey:@"metar"];
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

//
//  MainViewController.m
//  Yelp
//
//  Created by Timothy Lee on 3/21/14.
//  Copyright (c) 2014 codepath. All rights reserved.
//

#import "MainViewController.h"
#import "YelpClient.h"
#import "FilterViewController.h"
#import "BusinessCell.h"
#import "Business.h"

NSString * const kYelpConsumerKey = @"vxKwwcR_NMQ7WaEiQBK_CA";
NSString * const kYelpConsumerSecret = @"33QCvh5bIF5jIHR5klQr7RtBDhQ";
NSString * const kYelpToken = @"uRcRswHFYa1VkDrGV6LAW2F8clGh5JHV";
NSString * const kYelpTokenSecret = @"mqtKIxMIR4iBtBPZCmCLEb-Dz3Y";

NSString * const kYelpQueryTermPlaceholder = @"Restaurants";

@interface MainViewController ()

@property (nonatomic, strong) YelpClient *client;
@property (nonatomic, strong) NSArray *businesses;
@property (weak, nonatomic) IBOutlet UITableView *listingTableView;
@property (weak, nonatomic) BusinessCell* prototypeBusinessCell;
@property (nonatomic, strong) NSString *querySearchTerm;
@property (nonatomic, strong) UISearchBar *searchBar;

- (void)onFilterButton;
- (void)filterViewController:(FilterViewController *) FilterViewController didChangeFilters:(NSDictionary *)filters;
- (void)fetchBusinessesWithQuery:(NSString *)query params: (NSDictionary *)params;

@end

@implementation MainViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.querySearchTerm = kYelpQueryTermPlaceholder;
        // You can register for Yelp API keys here: http://www.yelp.com/developers/manage_api_keys
        self.client = [[YelpClient alloc] initWithConsumerKey:kYelpConsumerKey consumerSecret:kYelpConsumerSecret accessToken:kYelpToken accessSecret:kYelpTokenSecret];
        [self fetchBusinessesWithQuery:self.querySearchTerm params:nil];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupNavigationBar];
    [self setupTableView];
}

- (void)setupNavigationBar {
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Filter" style:UIBarButtonItemStylePlain target:self action:@selector(onFilterButton)];
    
    self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, 200, 64)];
    self.searchBar.placeholder = kYelpQueryTermPlaceholder;
    self.navigationItem.titleView = self.searchBar;
    self.searchBar.delegate = self;
}

- (void)setupTableView {
    self.listingTableView.delegate = self;
    self.listingTableView.dataSource = self;
    self.listingTableView.rowHeight = UITableViewAutomaticDimension;
    
    UINib *businessCellNib = [UINib nibWithNibName:@"BusinessCell" bundle:nil];
    [self.listingTableView registerNib:businessCellNib forCellReuseIdentifier:@"BusinessCell"];
}

#pragma mark - Custom setters

- (BusinessCell *)prototypeBusinessCell {
    if (_prototypeBusinessCell == nil) {
        _prototypeBusinessCell = [self.listingTableView dequeueReusableCellWithIdentifier:@"BusinessCell"];
    }
    return _prototypeBusinessCell;
}

# pragma mark - Search Bar methods

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
    self.querySearchTerm = searchBar.text;
    [self fetchBusinessesWithQuery:self.querySearchTerm params:nil];
}

#pragma mark - Table view methods

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    self.prototypeBusinessCell.business = self.businesses[indexPath.row];
    CGSize size = [self.prototypeBusinessCell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
    return size.height + 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    BusinessCell *cell = [tableView dequeueReusableCellWithIdentifier:@"BusinessCell" forIndexPath:indexPath];
    cell.business = self.businesses[indexPath.row];
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.businesses.count;
}

#pragma mark - Filter delegate methods

- (void)filterViewController:(FilterViewController *) FilterViewController didChangeFilters:(NSDictionary *)filters {
    self.searchBar.text = nil;
    self.querySearchTerm = kYelpQueryTermPlaceholder;
    [self fetchBusinessesWithQuery:self.querySearchTerm params:filters];
}

#pragma mark - Private Methods

- (void)fetchBusinessesWithQuery:(NSString *)query params: (NSDictionary *)params {
    [self.client searchWithTerm:query params:params success:^(AFHTTPRequestOperation *operation, id response) {
        self.businesses = [Business businessesWithDictionaries:response[@"businesses"]];
        [self.listingTableView reloadData];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"error: %@", [error description]);
    }];
}

- (void)onFilterButton {
    FilterViewController *vc = [[FilterViewController alloc] init];
    vc.delegate = self;
    UINavigationController *nvc = [[UINavigationController alloc] initWithRootViewController:vc];
    [self presentViewController:nvc animated:YES completion:nil];
}

@end

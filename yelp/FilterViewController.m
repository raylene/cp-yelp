//
//  FilterViewController.m
//  Yelp
//
//  Created by Raylene Yung on 10/25/14.
//  Copyright (c) 2014 codepath. All rights reserved.
//

#import "FilterViewController.h"
#import "SwitchCell.h"

@interface FilterViewController () <UITableViewDataSource, UITableViewDelegate, SwitchCellDelegate>

@property (nonatomic, readonly) NSDictionary *filters;
@property (weak, nonatomic) IBOutlet UITableView *filterTableView;

@property (nonatomic, strong) NSArray *sortByOptions;
@property (nonatomic, assign) NSInteger selectedSortIndex;

@property (nonatomic, strong) NSArray *distanceOptions;
@property (nonatomic, assign) NSInteger selectedDistanceIndex;

@property (nonatomic, strong) NSArray *categories;
@property (nonatomic, strong) NSMutableSet *selectedCategories;

@property (nonatomic, assign) NSInteger selectedDealOn;

@property (nonatomic, strong) NSArray *sectionTitles;

- (NSDictionary *)filters;
- (void)onCloseButton;
- (void)onApplyButton;
- (void)initSortByOptions;
- (void)initDistanceOptions;
- (void)initCategories;

@end

@implementation FilterViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if (self) {
        [self initCategories];
        self.selectedCategories = [NSMutableSet set];
        
        [self initSortByOptions];
        self.selectedSortIndex = 0;
        
        [self initDistanceOptions];
        self.selectedDistanceIndex = 0;
        
        self.selectedDealOn = 0;
        
        self.sectionTitles = @[@"Category", @"Sort By", @"Distance", @"Deals"];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Setup navigation bar
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(onCloseButton)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Search" style:UIBarButtonItemStylePlain target:self action:@selector(onApplyButton)];
    self.title = @"Filters";
    
    // Setup table view
    self.filterTableView.delegate = self;
    self.filterTableView.dataSource = self;
    self.filterTableView.rowHeight = UITableViewAutomaticDimension;
    [self.filterTableView registerNib:[UINib nibWithNibName:@"SwitchCell" bundle:nil] forCellReuseIdentifier:@"SwitchCell"];
}

#pragma mark - Table view methods

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
    header.textLabel.textColor = [UIColor grayColor];
    header.textLabel.font = [UIFont boldSystemFontOfSize:15];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return self.sectionTitles[section];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.sectionTitles.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Deal selection has 1 row
    if (section == 3) {
        return 1;
    }
    // Category, Sort By, and Distance each show 3 rows
    return 3;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    SwitchCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SwitchCell" forIndexPath:indexPath];

    // Category Section
    if (indexPath.section == 0) {
        cell.titleLabel.text = self.categories[indexPath.row][@"name"];
        cell.on = [self.selectedCategories containsObject:self.categories[indexPath.row]];
    } else if (indexPath.section == 1) {
        // Sort By
        cell.titleLabel.text = self.sortByOptions[indexPath.row][@"name"];
        cell.on = (BOOL)(indexPath.row == self.selectedSortIndex);
    } else if (indexPath.section == 2) {
        // Distance
        cell.titleLabel.text = self.distanceOptions[indexPath.row][@"name"];
        cell.on = (indexPath.row == self.selectedDistanceIndex);
    } else if (indexPath.section == 3) {
        // Deals
        cell.titleLabel.text = @"Offering a Deal";
        cell.on = self.selectedDealOn;
    }
    cell.delegate = self;
    return cell;
}

#pragma  mark - SwitchCellDelegate methods

- (void)switchCell:(SwitchCell *)cell didUpdateValue:(BOOL)value {
    NSIndexPath *indexPath = [self.filterTableView indexPathForCell:cell];
    // Categories
    if (indexPath.section == 0) {
        if (value) {
            [self.selectedCategories addObject:self.categories[indexPath.row]];
        } else {
            [self.selectedCategories removeObject:self.categories[indexPath.row]];
        }
    } else if (indexPath.section == 1 && value) {
        // Sort By
        self.selectedSortIndex = indexPath.row;
        [self.filterTableView reloadData];
    } else if (indexPath.section == 2 && value) {
        // Distance
        self.selectedDistanceIndex = indexPath.row;
        [self.filterTableView reloadData];
    } else if (indexPath.section == 3) {
        // Deals
        self.selectedDealOn = value;
    }
}

#pragma mark - Private methods

- (NSDictionary *)filters {
    NSMutableDictionary *filters = [NSMutableDictionary dictionary];
    if (self.selectedCategories.count > 0) {
        NSMutableArray *names = [NSMutableArray array];
        for (NSDictionary *category in self.selectedCategories) {
            [names addObject:category[@"code"]];
        }
        NSString *categoryFilter = [names componentsJoinedByString:@","];
        // Matches the Yelp API key
        [filters setObject:categoryFilter forKey:@"category_filter"];
    }
    [filters setObject:[NSNumber numberWithBool:self.selectedDealOn] forKey:@"deals_filter"];
    NSDictionary *radiusInfo = self.distanceOptions[self.selectedDistanceIndex];
    [filters setObject:[radiusInfo objectForKey:@"radius"] forKey:@"radius_filter"];
    [filters setObject:[NSNumber numberWithInt:(int)self.selectedSortIndex] forKey:@"sort"];
    return filters;
}

- (void)onCloseButton {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)onApplyButton {
    [self.delegate filterViewController:self didChangeFilters:self.filters];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)initSortByOptions {
    // http://www.yelp.com/developers/documentation/v2/search_api
    self.sortByOptions =
    @[
      @{@"name": @"Best Matched", @"code": @0},
      @{@"name" : @"Distance", @"code": @1},
      @{@"name" : @"Highest Rated", @"code": @2}
    ];
}

- (void)initDistanceOptions {
    self.distanceOptions =
    @[
      @{@"name" : @"500 meters", @"radius": @500},
      @{@"name" : @"1000 meters", @"radius": @1000},
      @{@"name" : @"2000 meters", @"radius": @2000}
    ];
}

- (void)initCategories {
    self.categories =
    @[
      @{@"name" : @"Afghan", @"code": @"afghani" },
      @{@"name" : @"African", @"code": @"african" },
      @{@"name" : @"American, New", @"code": @"newamerican" },
      @{@"name" : @"American, Traditional", @"code": @"tradamerican" },
      @{@"name" : @"Arabian", @"code": @"arabian" },
      @{@"name" : @"Argentine", @"code": @"argentine" },
      @{@"name" : @"Armenian", @"code": @"armenian" },
      @{@"name" : @"Asian Fusion", @"code": @"asianfusion" },
      @{@"name" : @"Asturian", @"code": @"asturian" },
      @{@"name" : @"Australian", @"code": @"australian" },
      @{@"name" : @"Austrian", @"code": @"austrian" },
      @{@"name" : @"Baguettes", @"code": @"baguettes" },
      @{@"name" : @"Bangladeshi", @"code": @"bangladeshi" },
      @{@"name" : @"Barbeque", @"code": @"bbq" },
      @{@"name" : @"Basque", @"code": @"basque" },
      @{@"name" : @"Bavarian", @"code": @"bavarian" },
      @{@"name" : @"Beer Garden", @"code": @"beergarden" },
      @{@"name" : @"Beer Hall", @"code": @"beerhall" },
      @{@"name" : @"Beisl", @"code": @"beisl" },
      @{@"name" : @"Belgian", @"code": @"belgian" },
      @{@"name" : @"Bistros", @"code": @"bistros" },
      @{@"name" : @"Black Sea", @"code": @"blacksea" },
      @{@"name" : @"Brasseries", @"code": @"brasseries" },
      @{@"name" : @"Brazilian", @"code": @"brazilian" },
      @{@"name" : @"Breakfast & Brunch", @"code": @"breakfast_brunch" },
      @{@"name" : @"British", @"code": @"british" },
      @{@"name" : @"Buffets", @"code": @"buffets" },
      @{@"name" : @"Bulgarian", @"code": @"bulgarian" },
      @{@"name" : @"Burgers", @"code": @"burgers" },
      @{@"name" : @"Burmese", @"code": @"burmese" },
      @{@"name" : @"Cafes", @"code": @"cafes" },
      @{@"name" : @"Cafeteria", @"code": @"cafeteria" },
      @{@"name" : @"Cajun/Creole", @"code": @"cajun" },
      @{@"name" : @"Cambodian", @"code": @"cambodian" },
      @{@"name" : @"Canadian", @"code": @"New)" },
      @{@"name" : @"Canteen", @"code": @"canteen" },
      @{@"name" : @"Caribbean", @"code": @"caribbean" },
      @{@"name" : @"Catalan", @"code": @"catalan" },
      @{@"name" : @"Chech", @"code": @"chech" },
      @{@"name" : @"Cheesesteaks", @"code": @"cheesesteaks" },
      @{@"name" : @"Chicken Shop", @"code": @"chickenshop" },
      @{@"name" : @"Chicken Wings", @"code": @"chicken_wings" },
      @{@"name" : @"Chilean", @"code": @"chilean" },
      @{@"name" : @"Chinese", @"code": @"chinese" },
      @{@"name" : @"Comfort Food", @"code": @"comfortfood" },
      @{@"name" : @"Corsican", @"code": @"corsican" },
      @{@"name" : @"Creperies", @"code": @"creperies" },
      @{@"name" : @"Cuban", @"code": @"cuban" },
      @{@"name" : @"Curry Sausage", @"code": @"currysausage" },
      @{@"name" : @"Cypriot", @"code": @"cypriot" },
      @{@"name" : @"Czech", @"code": @"czech" },
      @{@"name" : @"Czech/Slovakian", @"code": @"czechslovakian" },
      @{@"name" : @"Danish", @"code": @"danish" },
      @{@"name" : @"Delis", @"code": @"delis" },
      @{@"name" : @"Diners", @"code": @"diners" },
      @{@"name" : @"Dumplings", @"code": @"dumplings" },
      @{@"name" : @"Eastern European", @"code": @"eastern_european" },
      @{@"name" : @"Ethiopian", @"code": @"ethiopian" },
      @{@"name" : @"Fast Food", @"code": @"hotdogs" },
      @{@"name" : @"Filipino", @"code": @"filipino" },
      @{@"name" : @"Fish & Chips", @"code": @"fishnchips" },
      @{@"name" : @"Fondue", @"code": @"fondue" },
      @{@"name" : @"Food Court", @"code": @"food_court" },
      @{@"name" : @"Food Stands", @"code": @"foodstands" },
      @{@"name" : @"French", @"code": @"french" },
      @{@"name" : @"French Southwest", @"code": @"sud_ouest" },
      @{@"name" : @"Galician", @"code": @"galician" },
      @{@"name" : @"Gastropubs", @"code": @"gastropubs" },
      @{@"name" : @"Georgian", @"code": @"georgian" },
      @{@"name" : @"German", @"code": @"german" },
      @{@"name" : @"Giblets", @"code": @"giblets" },
      @{@"name" : @"Gluten-Free", @"code": @"gluten_free" },
      @{@"name" : @"Greek", @"code": @"greek" },
      @{@"name" : @"Halal", @"code": @"halal" },
      @{@"name" : @"Hawaiian", @"code": @"hawaiian" },
      @{@"name" : @"Heuriger", @"code": @"heuriger" },
      @{@"name" : @"Himalayan/Nepalese", @"code": @"himalayan" },
      @{@"name" : @"Hong Kong Style Cafe", @"code": @"hkcafe" },
      @{@"name" : @"Hot Dogs", @"code": @"hotdog" },
      @{@"name" : @"Hot Pot", @"code": @"hotpot" },
      @{@"name" : @"Hungarian", @"code": @"hungarian" },
      @{@"name" : @"Iberian", @"code": @"iberian" },
      @{@"name" : @"Indian", @"code": @"indpak" },
      @{@"name" : @"Indonesian", @"code": @"indonesian" },
      @{@"name" : @"International", @"code": @"international" },
      @{@"name" : @"Irish", @"code": @"irish" },
      @{@"name" : @"Island Pub", @"code": @"island_pub" },
      @{@"name" : @"Israeli", @"code": @"israeli" },
      @{@"name" : @"Italian", @"code": @"italian" },
      @{@"name" : @"Japanese", @"code": @"japanese" },
      @{@"name" : @"Jewish", @"code": @"jewish" },
      @{@"name" : @"Kebab", @"code": @"kebab" },
      @{@"name" : @"Korean", @"code": @"korean" },
      @{@"name" : @"Kosher", @"code": @"kosher" },
      @{@"name" : @"Kurdish", @"code": @"kurdish" },
      @{@"name" : @"Laos", @"code": @"laos" },
      @{@"name" : @"Laotian", @"code": @"laotian" },
      @{@"name" : @"Latin American", @"code": @"latin" },
      @{@"name" : @"Live/Raw Food", @"code": @"raw_food" },
      @{@"name" : @"Lyonnais", @"code": @"lyonnais" },
      @{@"name" : @"Malaysian", @"code": @"malaysian" },
      @{@"name" : @"Meatballs", @"code": @"meatballs" },
      @{@"name" : @"Mediterranean", @"code": @"mediterranean" },
      @{@"name" : @"Mexican", @"code": @"mexican" },
      @{@"name" : @"Middle Eastern", @"code": @"mideastern" },
      @{@"name" : @"Milk Bars", @"code": @"milkbars" },
      @{@"name" : @"Modern Australian", @"code": @"modern_australian" },
      @{@"name" : @"Modern European", @"code": @"modern_european" },
      @{@"name" : @"Mongolian", @"code": @"mongolian" },
      @{@"name" : @"Moroccan", @"code": @"moroccan" },
      @{@"name" : @"New Zealand", @"code": @"newzealand" },
      @{@"name" : @"Night Food", @"code": @"nightfood" },
      @{@"name" : @"Norcinerie", @"code": @"norcinerie" },
      @{@"name" : @"Open Sandwiches", @"code": @"opensandwiches" },
      @{@"name" : @"Oriental", @"code": @"oriental" },
      @{@"name" : @"Pakistani", @"code": @"pakistani" },
      @{@"name" : @"Parent Cafes", @"code": @"eltern_cafes" },
      @{@"name" : @"Parma", @"code": @"parma" },
      @{@"name" : @"Persian/Iranian", @"code": @"persian" },
      @{@"name" : @"Peruvian", @"code": @"peruvian" },
      @{@"name" : @"Pita", @"code": @"pita" },
      @{@"name" : @"Pizza", @"code": @"pizza" },
      @{@"name" : @"Polish", @"code": @"polish" },
      @{@"name" : @"Portuguese", @"code": @"portuguese" },
      @{@"name" : @"Potatoes", @"code": @"potatoes" },
      @{@"name" : @"Poutineries", @"code": @"poutineries" },
      @{@"name" : @"Pub Food", @"code": @"pubfood" },
      @{@"name" : @"Rice", @"code": @"riceshop" },
      @{@"name" : @"Romanian", @"code": @"romanian" },
      @{@"name" : @"Rotisserie Chicken", @"code": @"rotisserie_chicken" },
      @{@"name" : @"Rumanian", @"code": @"rumanian" },
      @{@"name" : @"Russian", @"code": @"russian" },
      @{@"name" : @"Salad", @"code": @"salad" },
      @{@"name" : @"Sandwiches", @"code": @"sandwiches" },
      @{@"name" : @"Scandinavian", @"code": @"scandinavian" },
      @{@"name" : @"Scottish", @"code": @"scottish" },
      @{@"name" : @"Seafood", @"code": @"seafood" },
      @{@"name" : @"Serbo Croatian", @"code": @"serbocroatian" },
      @{@"name" : @"Signature Cuisine", @"code": @"signature_cuisine" },
      @{@"name" : @"Singaporean", @"code": @"singaporean" },
      @{@"name" : @"Slovakian", @"code": @"slovakian" },
      @{@"name" : @"Soul Food", @"code": @"soulfood" },
      @{@"name" : @"Soup", @"code": @"soup" },
      @{@"name" : @"Southern", @"code": @"southern" },
      @{@"name" : @"Spanish", @"code": @"spanish" },
      @{@"name" : @"Steakhouses", @"code": @"steak" },
      @{@"name" : @"Sushi Bars", @"code": @"sushi" },
      @{@"name" : @"Swabian", @"code": @"swabian" },
      @{@"name" : @"Swedish", @"code": @"swedish" },
      @{@"name" : @"Swiss Food", @"code": @"swissfood" },
      @{@"name" : @"Tabernas", @"code": @"tabernas" },
      @{@"name" : @"Taiwanese", @"code": @"taiwanese" },
      @{@"name" : @"Tapas Bars", @"code": @"tapas" },
      @{@"name" : @"Tapas/Small Plates", @"code": @"tapasmallplates" },
      @{@"name" : @"Tex-Mex", @"code": @"tex-mex" },
      @{@"name" : @"Thai", @"code": @"thai" },
      @{@"name" : @"Traditional Norwegian", @"code": @"norwegian" },
      @{@"name" : @"Traditional Swedish", @"code": @"traditional_swedish" },
      @{@"name" : @"Trattorie", @"code": @"trattorie" },
      @{@"name" : @"Turkish", @"code": @"turkish" },
      @{@"name" : @"Ukrainian", @"code": @"ukrainian" },
      @{@"name" : @"Uzbek", @"code": @"uzbek" },
      @{@"name" : @"Vegan", @"code": @"vegan" },
      @{@"name" : @"Vegetarian", @"code": @"vegetarian" },
      @{@"name" : @"Venison", @"code": @"venison" },
      @{@"name" : @"Vietnamese", @"code": @"vietnamese" },
      @{@"name" : @"Wok", @"code": @"wok" },
      @{@"name" : @"Wraps", @"code": @"wraps" },
      @{@"name" : @"Yugoslav", @"code": @"yugoslav" }];
}
@end

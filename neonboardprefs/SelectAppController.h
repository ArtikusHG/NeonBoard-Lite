#import <Preferences/PSListController.h>

@interface SelectAppController : PSListController <UISearchResultsUpdating, UISearchBarDelegate>
@property (nonatomic, retain) UISearchController *searchController;
@property (nonatomic, retain) NSMutableArray *originalSpecifiers;
@end

#import <Preferences/PSListController.h>

@interface SelectThemeController : PSListController <UISearchResultsUpdating, UISearchBarDelegate>
@property (nonatomic, retain) UISearchController *searchController;
@property (nonatomic, retain) NSMutableArray *originalSpecifiers;
@end

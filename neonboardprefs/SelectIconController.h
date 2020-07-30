#import <Preferences/PSListController.h>

@interface SelectIconController : PSListController <UISearchResultsUpdating, UISearchBarDelegate, UIAlertViewDelegate>
@property (nonatomic, retain) UISearchController *searchController;
@property (nonatomic, retain) NSMutableArray *iconSpecifiers;
@property (nonatomic, retain) NSMutableArray *originalSpecifiers;
@property (nonatomic) BOOL shouldAutoLoadIcons;
@end

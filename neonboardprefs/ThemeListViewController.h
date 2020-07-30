#import <Preferences/PSListController.h>

@interface ThemeListViewController : PSViewController <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, retain) UITableView *table;
@property (nonatomic, retain) NSArray *allThemes;
@property (nonatomic, retain) NSMutableArray *themes;
@property (nonatomic, retain) NSMutableArray *enabledThemes;
@property (nonatomic, retain) NSMutableDictionary *prefs;
@end

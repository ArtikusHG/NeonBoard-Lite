#include "ThemeListViewController.h"
#define PLIST_PATH_Settings "/var/mobile/Library/Preferences/com.artikus.neonboardprefs.plist"

@implementation ThemeListViewController

@synthesize table;
@synthesize allThemes;
@synthesize themes;
@synthesize enabledThemes;
@synthesize prefs;

// my laziness, i guess
- (NSString *)titleForCellFromTheme:(NSString *)themeName {
	return ([[themeName substringFromIndex:themeName.length - 6] isEqualToString:@".theme"]) ? [themeName substringToIndex:themeName.length - 6] : themeName;
}

- (void)viewDidLoad {
	[super viewDidLoad];
	// get themes list
	allThemes = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:@"/Library/Themes/" error:nil];
	allThemes = [allThemes sortedArrayUsingSelector:@selector(compare:)];
	themes = [allThemes mutableCopy];
	// grab preferences
	prefs = [[NSDictionary dictionaryWithContentsOfURL:[NSURL fileURLWithPath:@PLIST_PATH_Settings] error:nil] mutableCopy] ? : [NSMutableDictionary dictionary];
	enabledThemes = [[prefs objectForKey:@"enabledThemes"] mutableCopy] ? : [NSMutableArray new];
	for (id object in enabledThemes) if ([themes containsObject:object]) [themes removeObject:object];
	themes = [[themes sortedArrayUsingSelector:@selector(compare:)] mutableCopy];
	// add tableview
	table = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, table.rowHeight * themes.count)];
	table.dataSource = self;
	table.delegate = self;
  table.allowsSelectionDuringEditing = YES;
	table.editing = YES;
	self.view = table;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return 2;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
	return (section == 0) ? @"Enabled themes" : @"Themes";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return (section == 0) ? enabledThemes.count : themes.count;
}

- (id)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:@"cell"];
	cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cell"];
	cell.textLabel.text = [self titleForCellFromTheme:(indexPath.section == 0) ? [enabledThemes objectAtIndex:indexPath.row] : [themes objectAtIndex:indexPath.row]];
	return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.section == 0) {
		[themes addObject:[enabledThemes objectAtIndex:indexPath.row]];
		themes = [[themes sortedArrayUsingSelector:@selector(compare:)] mutableCopy];
		[enabledThemes removeObjectAtIndex:indexPath.row];
	} else {
		[enabledThemes insertObject:[themes objectAtIndex:indexPath.row] atIndex:0];
		[themes removeObjectAtIndex:indexPath.row];
	}
	[self writeData];
	[table reloadData];
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
	if (sourceIndexPath.section != destinationIndexPath.section || sourceIndexPath.section != 0) return;
	id obj1 = [[enabledThemes objectAtIndex:sourceIndexPath.row] copy];
	id obj2 = [[enabledThemes objectAtIndex:destinationIndexPath.row] copy];
	[enabledThemes replaceObjectAtIndex:destinationIndexPath.row withObject:obj1];
	[enabledThemes replaceObjectAtIndex:sourceIndexPath.row withObject:obj2];
	[self writeData];
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath{
  return UITableViewCellEditingStyleNone;
}

- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
  return (indexPath.section == 0);
}

// thanks Julioverne again
- (void)writeData {
	[prefs setObject:enabledThemes forKey:@"enabledThemes"];
	[prefs writeToURL:[NSURL fileURLWithPath:@PLIST_PATH_Settings] error:nil];
}

@end

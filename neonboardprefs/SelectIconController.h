#import "PSSearchableListController.h"

@interface SelectIconController : PSSearchableListController <UIAlertViewDelegate>
@property (nonatomic, retain) NSMutableArray *iconSpecifiers;
@property (nonatomic) BOOL shouldAutoLoadIcons;
@end

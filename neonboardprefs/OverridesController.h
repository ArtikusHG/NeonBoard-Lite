#import <Preferences/PSListController.h>

@interface PSEditableListController : PSListController
@end

@interface OverridesController : PSEditableListController <UIAlertViewDelegate>
+ (instancetype)sharedInstance;
@property (nonatomic) NSInteger previousOverrideCount;
@end

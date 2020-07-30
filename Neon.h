#include <dlfcn.h>

@interface UIImage (Private)
+ (UIImage *)imageNamed:(NSString *)name inBundle:(NSBundle *)bundle;
+ (UIImage *)_applicationIconImageForBundleIdentifier:(NSString *)bundleIdentifier format:(int)format scale:(CGFloat)scale;
@end

@interface LSApplicationProxy : NSObject
@property (nonatomic, copy) NSString *boundApplicationIdentifier;
@property (nonatomic, copy) NSString * _boundApplicationIdentifier;
@property (nonatomic, readonly) NSString *localizedName;
@property (nonatomic, readonly) NSString *applicationIdentifier;
@property (nonatomic, readonly) NSURL *bundleURL;
+ (LSApplicationProxy *)applicationProxyForIdentifier:(NSString *)identifier;
@end

@interface LSApplicationWorkspace
+ (instancetype)defaultWorkspace;
- (NSMutableArray *)allInstalledApplications;
@end

@interface Neon : NSObject
+ (NSArray *)themes;
+ (NSDictionary *)prefs;
+ (NSDictionary *)overrideThemes;
+ (UIImage *)getMaskImage;
+ (NSString *)iconPathForBundleID:(NSString *)bundleID;
+ (NSString *)iconPathForBundleID:(NSString *)bundleID fromTheme:(NSString *)theme;
+ (NSString *)fullPathForImageNamed:(NSString *)name atPath:(NSString *)basePath;
+ (void)loadPrefs;
@end

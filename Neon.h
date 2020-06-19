@interface Neon : NSObject
+ (NSArray *)themes;
+ (NSDictionary *)prefs;
+ (NSString *)iconPathForBundleID:(NSString *)bundleID;
+ (NSString *)fullPathForImageNamed:(NSString *)name atPath:(NSString *)basePath;
@end

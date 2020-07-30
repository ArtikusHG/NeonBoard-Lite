// based on https://github.com/AnemoneTeam/Anemone-OSS. coolstar, thank you.

@interface ISImage : NSObject
- (instancetype)initWithCGImage:(CGImageRef)CGImage scale:(CGFloat)scale;
@end

@interface ISImageDescriptor
@property (assign, nonatomic) CGSize size;
@property (assign, nonatomic) BOOL shouldApplyMask;
@end

#include "Neon.h"
#include "UIColor+CSSColors.h"

NSMutableDictionary *dateSettings;
NSMutableDictionary *daySettings;

NSDictionary *defaultDateSettings;
NSDictionary *defaultDaySettings;

BOOL fontExists(NSString *fontName) {
  NSArray *families = [UIFont familyNames];
  if ([families containsObject:fontName]) return YES;
  for (NSString *family in families) {
    NSArray *names = [UIFont fontNamesForFamilyName:family];
    if ([names containsObject:fontName])  return YES;
  }
  return NO;
}

UIFont *calendarFontWithParams(NSString *fontName, CGFloat size, UIFontWeight weight) {
  if (fontName && fontExists(fontName)) return [UIFont fontWithName:fontName size:size];
  else return [UIFont systemFontOfSize:size weight:weight];
}

UIFont *calendarFontWithParamsLegacy(NSString *fontName, CGFloat size) {
  if (fontName && fontExists(fontName)) return [UIFont fontWithName:fontName size:size];
  else return [UIFont systemFontOfSize:size];
}

id dateObject(NSString *key) {
  return [dateSettings objectForKey:key] ? : [defaultDateSettings objectForKey:key];
}
id dayObject(NSString *key) {
  return [daySettings objectForKey:key] ? : [defaultDaySettings objectForKey:key];
}

// test non glyph too ok
void drawIconIntoContext(CGContextRef ctx, CGSize imageSize, BOOL masked, UIImage *base) {
  if (masked) CGContextClipToMask(ctx, CGRectMake(0, 0, imageSize.width, imageSize.height), [%c(Neon) getMaskImage].CGImage);

  if (!base) base = [UIImage imageWithContentsOfFile:[%c(Neon) iconPathForBundleID:@"com.apple.mobilecal"]];
  if (base) [base drawInRect:CGRectMake(0, 0, imageSize.height, imageSize.width)];
  else {
    [[UIColor whiteColor] setFill];
    UIRectFill(CGRectMake(0, 0, imageSize.height, imageSize.width));
  }

  NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
  [dateFormatter setDateStyle:NSDateFormatterNoStyle];
  [dateFormatter setTimeStyle:NSDateFormatterNoStyle];
  [dateFormatter setLocale:[NSLocale currentLocale]];
  NSDate *date = [NSDate date];
  [dateFormatter setDateFormat:@"d"];

  CGFloat proportion = imageSize.width / 60;
  CGSize size = CGSizeZero;
  if ([dateObject(@"FontSize") intValue] != 0) {
    NSString *day = [dateFormatter stringFromDate:date];
    if ([dateObject(@"TextCase") isEqualToString:@"lowercase"]) day = [day lowercaseString];
    else if ([dateObject(@"TextCase") isEqualToString:@"uppercase"]) day = [day uppercaseString];

    UIFont *dateFont;
    if(@available(iOS 8.2, *)) dateFont = calendarFontWithParams(dateObject(@"FontName"), [dateObject(@"FontSize") floatValue] * proportion, UIFontWeightLight);
    else dateFont = calendarFontWithParamsLegacy(dateObject(@"FontName") ? : @"HelveticaNeue-UltraLight", [dateObject(@"FontSize") floatValue] * proportion);
    size = [day sizeWithAttributes:@{NSFontAttributeName:dateFont}];

    CGContextSetShadowWithColor(ctx, CGSizeMake([dateObject(@"ShadowXoffset") floatValue] * proportion, [dateObject(@"ShadowYoffset") floatValue] * proportion), [dateObject(@"ShadowBlurRadius") floatValue], [(UIColor *)dateObject(@"ShadowColor") CGColor]);
    CGContextSetAlpha(ctx, CGColorGetAlpha([(UIColor *)dateObject(@"TextColor") CGColor]));
    [day drawInRect:CGRectMake([dateObject(@"TextXoffset") floatValue] * proportion + ((imageSize.width - size.width) / 2.0f), [dateObject(@"TextYoffset") floatValue] * proportion, size.width, size.height) withAttributes:@{NSFontAttributeName:dateFont, NSForegroundColorAttributeName:(UIColor *)dateObject(@"TextColor") ? : [UIColor blackColor]}];
  }
  if ([dayObject(@"FontSize") intValue] != 0) {
    UIColor *dayTextColor = dayObject(@"TextColor") ? : [UIColor redColor];
    [dateFormatter setDateFormat:@"EEEE"];
    NSString *dayOfWeek = [dateFormatter stringFromDate:date];
    if ([dayObject(@"TextCase") isEqualToString:@"lowercase"]) dayOfWeek = [dayOfWeek lowercaseString];
    else if ([dayObject(@"TextCase") isEqualToString:@"uppercase"]) dayOfWeek = [dayOfWeek uppercaseString];

    UIFont *dayOfWeekFont;
    if(@available(iOS 8.2, *)) dayOfWeekFont = calendarFontWithParams(dayObject(@"FontName"), [dayObject(@"FontSize") floatValue] * proportion, UIFontWeightLight);
    else dayOfWeekFont = calendarFontWithParamsLegacy(dayObject(@"FontName"), [dayObject(@"FontSize") floatValue] * proportion);    size = [dayOfWeek sizeWithAttributes:@{NSFontAttributeName:dayOfWeekFont}];
    CGContextSetShadowWithColor(ctx, CGSizeMake([dayObject(@"ShadowXoffset") floatValue] * proportion, [dayObject(@"ShadowXoffset") floatValue] * proportion), [dayObject(@"ShadowBlurRadius") floatValue], [(UIColor *)dayObject(@"ShadowColor") CGColor]);
    CGContextSetAlpha(ctx, CGColorGetAlpha([(UIColor *)dayObject(@"TextColor") CGColor]));
    [dayOfWeek drawAtPoint:CGPointMake([dayObject(@"TextXoffset") floatValue] * proportion + ((imageSize.width - size.width) / 2.0f), [dayObject(@"TextYoffset") floatValue] * proportion) withAttributes:@{NSFontAttributeName:dayOfWeekFont, NSForegroundColorAttributeName:dayTextColor}];
  }
}

UIImage *calendarIconForSize(CGSize imageSize, BOOL masked) {
  UIGraphicsBeginImageContextWithOptions(imageSize, NO, [UIScreen mainScreen].scale);
  CGContextRef ctx = UIGraphicsGetCurrentContext();
  drawIconIntoContext(ctx, imageSize, masked, nil);
  UIImage *icon = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  return icon;
}

%group Calendar

%hook CUIKIcon
- (ISImage *)imageForImageDescriptor:(ISImageDescriptor *)descriptor {
  UIImage *icon = calendarIconForSize(descriptor.size, descriptor.shouldApplyMask);
  ISImage *image = [[%c(ISImage) alloc] initWithCGImage:icon.CGImage scale:[UIScreen mainScreen].scale];
  return image;
}
%end

%end

%group Calendar_1012

%hook CUIKCalendarApplicationIcon
+ (void)_drawIconInContext:(CGContextRef)ctx imageSize:(CGSize)imageSize iconBase:(UIImage *)base calendar:(NSCalendar *)calendar dayNumberString:(NSString *)dayNumberString dateNameBlock:(id)dateNameBlock dateNameFormatType:(long long)dateNameFormatType format:(long long)format showGrid:(BOOL)showGrid {
  drawIconIntoContext(ctx, imageSize, YES, base);
}
%end

%hook WGCalendarWidgetInfo
- (UIImage *)_iconWithFormat:(int)format {
  return calendarIconForSize(%orig.size, YES);
}
- (UIImage *)_queue_iconWithFormat:(int)format forWidgetWithIdentifier:(NSString *)widgetIdentifier extension:(id)extension {
  return calendarIconForSize(%orig.size, YES);
}
%end

%end

%group CalendarOlder

%hook SBCalendarApplicationIcon

- (void)_drawIconIntoCurrentContextWithImageSize:(CGSize)imageSize iconBase:(UIImage *)base {
  drawIconIntoContext(UIGraphicsGetCurrentContext(), imageSize, YES, base);
}

- (UIImage *)_compositedIconImageForFormat:(int)format withBaseImageProvider:(UIImage *(^)())imageProvider {
  UIImage *baseImage = imageProvider();
	UIGraphicsBeginImageContextWithOptions(baseImage.size, NO, [UIScreen mainScreen].scale);
  drawIconIntoContext(UIGraphicsGetCurrentContext(), baseImage.size, YES, baseImage);
	UIImage *finalImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	return finalImage;
}

%end

%end

%ctor {
  // valentine is a tweak of mine that changes the calendar icon's style to the ios 14 beta 2 one; so if it's installed, i don't wanna override that
  if ([[NSFileManager defaultManager] fileExistsAtPath:@"/Library/MobileSubstrate/DynamicLibraries/Valentine.dylib"]) return;
  if (!%c(Neon)) dlopen("/Library/MobileSubstrate/DynamicLibraries/NeonEngine.dylib", RTLD_LAZY);
  if (!%c(Neon)) return;

  if (![%c(Neon) prefs]) return;
  NSString *overrideTheme = [[%c(Neon) overrideThemes] objectForKey:@"com.apple.mobilecal"];
  if (overrideTheme) {
    if ([overrideTheme isEqualToString:@"none"]) return;

    NSString *path = [NSString stringWithFormat:@"/Library/Themes/%@/Info.plist", overrideTheme];
		if ([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:nil]) {
      NSDictionary *themeDict;
      if (@available(iOS 11.0, *)) themeDict = [NSDictionary dictionaryWithContentsOfURL:[NSURL fileURLWithPath:path] error:nil];
      else themeDict = [NSDictionary dictionaryWithContentsOfFile:path];
      if (themeDict) {
    		dateSettings = [themeDict[@"CalendarIconDateSettings"] mutableCopy];
    		daySettings = [themeDict[@"CalendarIconDaySettings"] mutableCopy];
      }
    }
  } else {
    for (NSString *theme in [[%c(Neon) prefs] objectForKey:@"enabledThemes"]) {
  		NSString *path = [NSString stringWithFormat:@"/Library/Themes/%@/Info.plist", theme];
      if (![[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:nil]) continue;
      NSDictionary *themeDict;
      if (@available(iOS 11.0, *)) themeDict = [NSDictionary dictionaryWithContentsOfURL:[NSURL fileURLWithPath:path] error:nil];
      else themeDict = [NSDictionary dictionaryWithContentsOfFile:path];
      dateSettings = [themeDict[@"CalendarIconDateSettings"] mutableCopy];
  		daySettings = [themeDict[@"CalendarIconDaySettings"] mutableCopy];
      if (dateSettings || daySettings) break;
  	}
  }

	defaultDateSettings = @{
		@"FontSize" : @39.5f,
		@"TextXoffset" : @0.0f,
		@"TextYoffset" : @0.0f,
		@"ShadowXoffset" : @0.0f,
		@"ShadowYoffset" : @0.0f,
		@"ShadowBlurRadius" : @0.0f,
    @"TextColor" : [UIColor blackColor],
    @"ShadowColor" : [UIColor clearColor]
	};
	defaultDaySettings = @{
		@"FontSize" : @10.0f,
		@"TextXoffset" : @0.0f,
		@"TextYoffset" : @0.0f,
		@"ShadowXoffset" : @0.0f,
		@"ShadowYoffset" : @0.0f,
		@"ShadowBlurRadius" : @0.0f,
    @"TextColor" : [UIColor redColor],
    @"ShadowColor" : [UIColor clearColor]
	};

	if ([dateSettings objectForKey:@"TextCase"]) [dateSettings setObject:[[dateSettings objectForKey:@"TextCase"] lowercaseString] forKey:@"TextColor"];
	if ([dateSettings objectForKey:@"TextColor"]) [dateSettings setObject:[UIColor colorWithCSS:[dateSettings objectForKey:@"TextColor"]] forKey:@"TextColor"];
	if ([dateSettings objectForKey:@"ShadowColor"]) [dateSettings setObject:[UIColor colorWithCSS:[dateSettings objectForKey:@"ShadowColor"]] forKey:@"ShadowColor"];

	if ([daySettings objectForKey:@"TextCase"]) [daySettings setObject:[[daySettings objectForKey:@"TextCase"] lowercaseString] forKey:@"TextColor"];
	if ([daySettings objectForKey:@"TextColor"]) [daySettings setObject:[UIColor colorWithCSS:[daySettings objectForKey:@"TextColor"]] forKey:@"TextColor"];
	if ([daySettings objectForKey:@"ShadowColor"]) [daySettings setObject:[UIColor colorWithCSS:[daySettings objectForKey:@"ShadowColor"]] forKey:@"ShadowColor"];

  if (!dateSettings) dateSettings = [NSMutableDictionary new];
  if (!daySettings) daySettings = [NSMutableDictionary new];
  dateSettings[@"TextYoffset"] = [NSNumber numberWithFloat:[dateSettings[@"TextYoffset"] floatValue] + 12.0f];
  daySettings[@"TextYoffset"] = [NSNumber numberWithFloat:[daySettings[@"TextYoffset"] floatValue] + 6.0f];

  if (kCFCoreFoundationVersionNumber >= 1665.15) %init(Calendar);
  else if (kCFCoreFoundationVersionNumber >= 1348.00) %init(Calendar_1012);
  else %init(CalendarOlder);
}

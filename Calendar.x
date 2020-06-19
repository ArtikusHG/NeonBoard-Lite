// https://github.com/AnemoneTeam/Anemone-OSS

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

id dateObject(NSString *key) {
  return [dateSettings objectForKey:key] ? : [defaultDateSettings objectForKey:key];
}
id dayObject(NSString *key) {
  return [daySettings objectForKey:key] ? : [defaultDaySettings objectForKey:key];
}

%group Calendar

%hook CUIKDefaultIconGenerator

+ (void)_drawIconInContext:(CGContextRef)ctx imageSize:(CGSize)imageSize scale:(double)scale iconBase:(UIImage *)base calendar:(id)calendar dayNumberString:(NSString *)dayNumberString dateNameBlock:(id)dateNameBlock dateNameFormatType:(long long)format showGrid:(BOOL)showGrid {
  base = [UIImage imageWithContentsOfFile:[Neon iconPathForBundleID:@"com.apple.mobilecal"]] ? : base;
  //if (!dayPrefs && !datePrefs)
  if (!ctx) return;
  [base drawInRect:CGRectMake(0, 0, imageSize.width, imageSize.height)];

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

  	UIFont *dateFont = calendarFontWithParams(dateObject(@"FontName"), [dateObject(@"FontSize") floatValue] * proportion, UIFontWeightLight);
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

    UIFont *dayOfWeekFont = calendarFontWithParams(dayObject(@"FontName"), [dayObject(@"FontSize") floatValue] * proportion, UIFontWeightBold);
  	size = [dayOfWeek sizeWithAttributes:@{NSFontAttributeName:dayOfWeekFont}];
  	CGContextSetShadowWithColor(ctx, CGSizeMake([dayObject(@"ShadowXoffset") floatValue] * proportion, [dayObject(@"ShadowXoffset") floatValue] * proportion), [dayObject(@"ShadowBlurRadius") floatValue], [(UIColor *)dayObject(@"ShadowColor") CGColor]);
  	CGContextSetAlpha(ctx, CGColorGetAlpha([(UIColor *)dayObject(@"TextColor") CGColor]));
  	[dayOfWeek drawAtPoint:CGPointMake([dayObject(@"TextXoffset") floatValue] * proportion + ((imageSize.width - size.width) / 2.0f), [dayObject(@"TextYoffset") floatValue] * proportion) withAttributes:@{NSFontAttributeName:dayOfWeekFont, NSForegroundColorAttributeName:dayTextColor}];
  }}

%end

%end

%ctor {
  if (![Neon prefs]) return;
  for (NSString *theme in [[Neon prefs] objectForKey:@"enabledThemes"]) {
		NSString *path = [NSString stringWithFormat:@"/Library/Themes/%@/Info.plist", theme];
		if (![[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:nil]) continue;
		NSDictionary *themeDict = [NSDictionary dictionaryWithContentsOfURL:[NSURL fileURLWithPath:path] error:nil];
		if (!themeDict) continue;
		dateSettings = [themeDict[@"CalendarIconDateSettings"] mutableCopy];
		daySettings = [themeDict[@"CalendarIconDaySettings"] mutableCopy];
		if (!dateSettings && !daySettings) continue;
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

	%init(Calendar)
}

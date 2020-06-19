#include "Neon.h"

// Disable dark overlay
%group NoOverlay
%hook SBIconView
- (void)setHighlighted:(BOOL)isHighlighted { %orig(NO); }
%end
%end

// Hide icon labels
%group HideLabels
%hook SBIconView
- (CGRect)_frameForLabel {
  return CGRectNull;
}
%end
%end

// Hide dock background
%group NoDockBg
%hook SBDockView
- (void)setBackgroundAlpha:(double)setBackgroundAlpha { %orig(0); }
%end
%end

%group NoDockBg
%hook SBDockView
- (void)setBackgroundView:(UIView *)backgroundView {}
%end
%end

// Hide page dots
%group NoPageDots
%hook SBIconListPageControl
- (void)setHidden:(BOOL)isHidden { %orig(YES); }
%end
%end

// Hide folder icon background
%group NoFolderIconBgiOS13
%hook SBFolderIconImageView
- (void)setBackgroundView:(UIView *)backgroundView {}
%end
%end

%ctor {
  NSDictionary *prefs = [Neon prefs];
  if (!prefs) return;
  if([[prefs valueForKey:@"kNoOverlay"] boolValue]) %init(NoOverlay);
  if([[prefs valueForKey:@"kHideLabels"] boolValue]) %init(HideLabels);
  if([[prefs valueForKey:@"kNoDockBg"] boolValue]) %init(NoDockBg);
  if([[prefs valueForKey:@"kNoPageDots"] boolValue]) %init(NoPageDots);
  if([[prefs valueForKey:@"kNoFolderIconBg"] boolValue]) %init(NoFolderIconBgiOS13);
}

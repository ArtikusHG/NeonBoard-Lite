include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = neonboardprefs

DEBUG = 0
FINALPACKAGE = 1

ARCHS = arm64 arm64e
TARGET := iphone:clang:13.5:13.0

neonboardprefs_FILES = NBPRootListController.m CustomizationController.m ThemeListViewController.m
neonboardprefs_INSTALL_PATH = /Library/PreferenceBundles
neonboardprefs_FRAMEWORKS = UIKit
neonboardprefs_PRIVATE_FRAMEWORKS = Preferences
neonboardprefs_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/neonboardprefs.plist$(ECHO_END)

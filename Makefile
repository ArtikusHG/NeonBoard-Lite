#DEBUG = 0
#FINALPACKAGE = 1
THEOS_DEVICE_IP = 192.168.0.34
#ARCHS = arm64 arm64e
ARCHS = arm64
TARGET = iphone:clang:13.5:13.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = neonboardlite

neonboardlite_FILES = Calendar.x Clock.xm Customizations.x UIColor+CSSColors.m AltIconPicker.xm
neonboardlite_FRAMEWORKS = UIKit
neonboardlite_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
SUBPROJECTS += neonboardprefs neonengine neoncore
include $(THEOS_MAKE_PATH)/aggregate.mk

after-install::
	install.exec "rm -rf /var/containers/Shared/SystemGroup/systemgroup.com.apple.lsd.iconscache/Library/Caches/com.apple.IconsCache && killall -KILL iconservicesagent && killall -9 iconservicesagent SpringBoard"

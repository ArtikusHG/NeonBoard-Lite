export DEBUG = 0
export FINALPACKAGE = 1
export ARCHS = armv7 arm64 arm64e
#export ARCHS = arm64
export TARGET = iphone:clang:13.5:7.0

THEOS_DEVICE_IP = 192.168.0.18
#THEOS_DEVICE_PORT = 2222

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = NeonBoardLite

NeonBoardLite_FILES = Calendar.x Clock.xm Customizations.xm UIColor+CSSColors.m
NeonBoardLite_FRAMEWORKS = UIKit
NeonBoardLite_PRIVATE_FRAMEWORKS = AppSupport
NeonBoardLite_CFLAGS = -fobjc-arc -Wall

include $(THEOS_MAKE_PATH)/tweak.mk
SUBPROJECTS += neonboardprefs neonengine neoncore
include $(THEOS_MAKE_PATH)/aggregate.mk

after-install::
	install.exec "rm -rf /var/containers/Shared/SystemGroup/systemgroup.com.apple.lsd.iconscache/Library/Caches/com.apple.IconsCache && rm -rf /var/mobile/Library/Caches/MappedImageCache/Persistent && killall -KILL lsd lsdiconservice && killall -9 lsd SpringBoard"

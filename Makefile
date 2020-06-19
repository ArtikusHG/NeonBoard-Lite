DEBUG = 0
FINALPACKAGE = 1
THEOS_DEVICE_IP = 192.168.0.34
ARCHS = arm64 arm64e
TARGET = iphone:clang:13.5:13.0

INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = neonboardlite

neonboardlite_FILES = Neon.x Icons.x Calendar.x Clock.xm Customizations.x UIColor+CSSColors.m
neonboardlite_CFLAGS = -fobjc-arc
neonboardlite_FRAMEWORKS = UIKit
neonboardlite_LIBRARIES = MobileGestalt
neonboardlite_LDFLAGS += -Llibs/

include $(THEOS_MAKE_PATH)/tweak.mk
SUBPROJECTS += neonboardprefs
include $(THEOS_MAKE_PATH)/aggregate.mk

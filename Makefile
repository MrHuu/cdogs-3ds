#---------------------------------------------------------------------------------
.SUFFIXES:
#---------------------------------------------------------------------------------

#--- Path to DEVKITPRO ---
ifeq ($(strip $(DEVKITPRO)),)
$(error "Please set DEVKITPRO in your environment. export DEVKITPRO=<path to>devkitPRO")
endif

#--- Path to DEVKITARM ---
ifeq ($(strip $(DEVKITARM)),)
export DEVKITARM=$(DEVKITPRO)/devkitARM
endif

#--- Path to PORTLIBS ---
ifeq ($(strip $(PORTLIBS)),)
export PORTLIBS=$(DEVKITPRO)/portlibs/3ds
endif

#--- Path to bannertool ---
ifeq ($(strip $(TOOLDIR)),)
export TOOLDIR=$(DEVKITPRO)/tools/bin
endif

TOPDIR ?= $(CURDIR)
include $(DEVKITARM)/3ds_rules

#---------------------------------------------------------------------------------
# TARGET is the name of the output
# BUILD is the directory where object files & intermediate files will be placed
# SOURCES is a list of directories containing source code
# DATA is a list of directories containing data files
# INCLUDES is a list of directories containing header files
#
# ROMFS is the directory which contains the RomFS, relative to the Makefile (Optional)
# APP_TITLE is the name of the app stored in the SMDH file (Optional)
# APP_DESCRIPTION is the description of the app stored in the SMDH file (Optional)
# APP_AUTHOR is the author of the app stored in the SMDH file (Optional)
# APP_LOGO is the filename of the boot animation, .cia only (.bin)(Optional)
# APP_ICON is the filename of the icon (.png)
#---------------------------------------------------------------------------------

TARGET				:=	C-Dogs3DS
BUILD				:=	src_build
SOURCES				:=	src
DATA				:=	data
INCLUDES			:=	src/include src/missions
#ROMFS				:=	romfs

SDLCONFIG			:=	arm-none-eabi-pkg-config
SOUND_CODE			:=	sdlmixer
OGG_USE_TREMOR		:=	true

#---------------------------------------------------------------------------------
# options for .cia generation
#---------------------------------------------------------------------------------

APP_TITLE			:=	$(TARGET)
APP_DESCRIPTION		:=	Port of C-Dogs SDL
APP_AUTHOR			:=	MrHuu

APP_PRODUCT_CODE	:=	CTR-P-CDGS
APP_UNIQUE_ID		:=	0xFF335
APP_VERSION_MAJOR	:=	0
APP_VERSION_MINOR	:=	0
APP_VERSION_MICRO	:=	1

RSF					:=	$(TOPDIR)/build/ctr/template.rsf
#APP_LOGO			:=	$(TOPDIR)/build/ctr/hb_logo.bin
APP_ICON			:=	$(TOPDIR)/build/ctr/icon.png

BANNER_IMAGE_FILE	:=	$(TOPDIR)/build/ctr/banner.png
BANNER_AUDIO_FILE	:=	$(TOPDIR)/build/ctr/audio.wav

#---------------------------------------------------------------------------------
# options for code generation
#---------------------------------------------------------------------------------
ARCH		:=	-march=armv6k -mtune=mpcore -mfloat-abi=hard -mtp=soft

CFLAGS		:=	-g -Wall -O2 -mword-relocations \
				-fomit-frame-pointer -ffunction-sections \
				$(ARCH)

#CFLAGS		+=	$(INCLUDE) -D_3DS -DSYS_CTR -DSND_SDLMIXER -DCDOGS_DATA_DIR=\"$(DATADIR)\"
CFLAGS		+=	$(INCLUDE) -D_3DS -DSYS_CTR -DSND_SDLMIXER
CXXFLAGS	:=	$(CFLAGS) -fno-rtti -fno-exceptions -std=gnu++11

ASFLAGS		:=	-g $(ARCH)
LDFLAGS		=	-specs=3dsx.specs -g $(ARCH) -Wl,-Map,$(notdir $*.map)

LIBS		:=	-lSDL_image -lSDL_mixer -lSDL -lmad -lmikmod -lvorbisidec -logg -lcitro3d -lctru -lm

#---------------------------------------------------------------------------------
# list of directories containing libraries, this must be the top level containing
# include and lib
#---------------------------------------------------------------------------------
LIBDIRS		:=	$(CTRULIB) $(PORTLIBS)


#---------------------------------------------------------------------------------
# no real need to edit anything past this point unless you need to add additional
# rules for different file extensions
#---------------------------------------------------------------------------------
ifneq ($(BUILD),$(notdir $(CURDIR)))
#---------------------------------------------------------------------------------

export OUTPUT	:=	$(CURDIR)/$(TARGET)
export TOPDIR	:=	$(CURDIR)

export VPATH	:=	$(foreach dir,$(SOURCES),$(CURDIR)/$(dir)) \
			$(foreach dir,$(DATA),$(CURDIR)/$(dir))

export DEPSDIR	:=	$(CURDIR)/$(BUILD)

ifeq ($(EDITOR),)
	CDOGS_OBJS	=	cdogs.o
else
	CDOGS_OBJS	=	cdogsed.o
endif


CDOGS_OBJS	+=	\
	draw.o		\
	pics.o		\
	actors.o	\
	map.o		\
	sounds.o	\
	defs.o		\
	objs.o		\
	gamedata.o	\
	ai.o		\
	triggers.o	\
	input.o		\
	prep.o		\
	hiscores.o	\
	automap.o	\
	mission.o	\
	game.o		\
	mainmenu.o	\
	password.o	\
	files.o		\
	menu.o		\
	joystick.o	\
	grafx.o		\
	blit.o		\
	text.o		\
	keyboard.o	\
	events.o	\
	utils.o		\
	drawtools.o


CFILES		:=	$(CDOGS_OBJS)
CPPFILES	:=	$(foreach dir,$(SOURCES),$(notdir $(wildcard $(dir)/*.cpp)))
SFILES		:=	$(foreach dir,$(SOURCES),$(notdir $(wildcard $(dir)/*.s)))
PICAFILES	:=	$(foreach dir,$(SOURCES),$(notdir $(wildcard $(dir)/*.v.pica)))
SHLISTFILES	:=	$(foreach dir,$(SOURCES),$(notdir $(wildcard $(dir)/*.shlist)))
BINFILES	:=	$(foreach dir,$(DATA),$(notdir $(wildcard $(dir)/*.*)))

#---------------------------------------------------------------------------------
# use CXX for linking C++ projects, CC for standard C
#---------------------------------------------------------------------------------
ifeq ($(strip $(CPPFILES)),)
#---------------------------------------------------------------------------------
	export LD	:=	$(CC)
#---------------------------------------------------------------------------------
else
#---------------------------------------------------------------------------------
	export LD	:=	$(CXX)
#---------------------------------------------------------------------------------
endif
#---------------------------------------------------------------------------------

export OFILES			:=	$(addsuffix .o,$(BINFILES)) \
							$(PICAFILES:.v.pica=.shbin.o) $(SHLISTFILES:.shlist=.shbin.o) \
							$(CPPFILES:.cpp=.o) $(CFILES:.c=.o) $(SFILES:.s=.o)

export INCLUDE			:=	$(foreach dir,$(INCLUDES),-I$(CURDIR)/$(dir)) \
							$(foreach dir,$(LIBDIRS),-I$(dir)/include) \
							-I$(CURDIR)/$(BUILD) \
							-I$(PORTLIBS)/include/SDL

export LIBPATHS			:=	$(foreach dir,$(LIBDIRS),-L$(dir)/lib)

export _3DSXFLAGS		+=	--smdh=$(CURDIR)/$(TARGET).smdh

ifneq ($(ROMFS),)
	export _3DSXFLAGS	+=	--romfs=$(CURDIR)/$(ROMFS)
endif

.PHONY: $(BUILD) clean all
#---------------------------------------------------------------------------------
all: $(BUILD)

$(BUILD):
	@[ -d $@ ] || mkdir -p $@
	@$(MAKE) --no-print-directory -C $(BUILD) -f $(CURDIR)/Makefile

#---------------------------------------------------------------------------------
clean:
	@echo clean ...
	@rm -fr $(BUILD) $(TARGET).3dsx $(OUTPUT).smdh $(TARGET).elf $(TARGET).cia

#---------------------------------------------------------------------------------
else

DEPENDS						:=	$(OFILES:.o=.d)

BANNER_IMAGE_ARG			:=	-i $(BANNER_IMAGE_FILE)
BANNER_AUDIO_ARG			:=	-a $(BANNER_AUDIO_FILE)

ifneq ($(APP_LOGO),)
	APP_LOGO_ID				=	Homebrew
	COMMON_MAKEROM_PARAMS	+=	-logo $(APP_LOGO)
else
	APP_LOGO_ID				=	Nintendo
endif

COMMON_MAKEROM_PARAMS		:= -rsf $(RSF) -target t -exefslogo -elf $(OUTPUT).elf -icon icon.icn \
-banner banner.bnr -DAPP_LOGO_ID="$(APP_LOGO_ID)" -DAPP_TITLE="$(APP_TITLE)" -DAPP_PRODUCT_CODE="$(APP_PRODUCT_CODE)" \
-DAPP_UNIQUE_ID="$(APP_UNIQUE_ID)" -DAPP_SYSTEM_MODE="64MB" -DAPP_SYSTEM_MODE_EXT="Legacy" \
-major "$(APP_VERSION_MAJOR)" -minor "$(APP_VERSION_MINOR)" -micro "$(APP_VERSION_MICRO)"

ifneq ($(ROMFS),)
	APP_ROMFS				:=	$(TOPDIR)/$(ROMFS)
	COMMON_MAKEROM_PARAMS	+=	-DAPP_ROMFS="$(APP_ROMFS)" 
endif

ifeq ($(OS),Windows_NT)
	MAKEROM		=	makerom.exe
	BANNERTOOL	=	bannertool.exe
else
	MAKEROM		=	$(TOOLDIR)/makerom
	BANNERTOOL	=	$(TOOLDIR)/bannertool
endif

#---------------------------------------------------------------------------------
# main targets
#---------------------------------------------------------------------------------
.PHONY : all

all					:	$(OUTPUT).3dsx $(OUTPUT).cia

$(OUTPUT).3dsx		:	$(OUTPUT).elf $(OUTPUT).smdh

$(OUTPUT).elf		:	$(OFILES)

$(OUTPUT).cia		:	$(OUTPUT).elf banner.bnr icon.icn
	@$(MAKEROM) -f cia -o $(OUTPUT).cia -DAPP_ENCRYPTED=false $(COMMON_MAKEROM_PARAMS)
	@echo "built ... $(TARGET).cia"

banner.bnr : $(BANNER_IMAGE_FILE) $(BANNER_AUDIO_FILE)
	@$(BANNERTOOL) makebanner $(BANNER_IMAGE_ARG) $(BANNER_AUDIO_ARG) -o banner.bnr > /dev/null

icon.icn : $(APP_ICON)
	@$(BANNERTOOL) makesmdh -s "$(APP_TITLE)" -l "$(APP_TITLE)" -p "$(APP_AUTHOR)" -i $(APP_ICON) -o icon.icn > /dev/null


#---------------------------------------------------------------------------------
# you need a rule like this for each extension you use as binary data
#---------------------------------------------------------------------------------
%.bin.o	:	%.bin
#---------------------------------------------------------------------------------
	@echo $(notdir $<)
	@$(bin2o)

#---------------------------------------------------------------------------------
# rules for assembling GPU shaders
#---------------------------------------------------------------------------------
define shader-as
	$(eval CURBIN := $(patsubst %.shbin.o,%.shbin,$(notdir $@)))
	picasso -o $(CURBIN) $1
	bin2s $(CURBIN) | $(AS) -o $@
	echo "extern const u8" `(echo $(CURBIN) | sed -e 's/^\([0-9]\)/_\1/' | tr . _)`"_end[];" > `(echo $(CURBIN) | tr . _)`.h
	echo "extern const u8" `(echo $(CURBIN) | sed -e 's/^\([0-9]\)/_\1/' | tr . _)`"[];" >> `(echo $(CURBIN) | tr . _)`.h
	echo "extern const u32" `(echo $(CURBIN) | sed -e 's/^\([0-9]\)/_\1/' | tr . _)`_size";" >> `(echo $(CURBIN) | tr . _)`.h
endef

%.shbin.o : %.v.pica %.g.pica
	@echo $(notdir $^)
	@$(call shader-as,$^)

%.shbin.o : %.v.pica
	@echo $(notdir $<)
	@$(call shader-as,$<)

%.shbin.o : %.shlist
	@echo $(notdir $<)
	@$(call shader-as,$(foreach file,$(shell cat $<),$(dir $<)/$(file)))

-include $(DEPENDS)

#---------------------------------------------------------------------------------------
endif
#---------------------------------------------------------------------------------------

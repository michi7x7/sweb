# $Id: common.mk,v 1.1 2005/04/12 17:41:22 nomenquis Exp $
#
# $Log:  $
#
#


#MAKEFLAGS += --no-print-directory
MAKEFLAGS += --silent 

ifeq ($(PROJECT_MAKE_SUPPORT_ROOT),)
PROJECT_MAKE_SUPPORT_ROOT := $(PROJECT_ROOT)/make-support
endif


include $(PROJECT_MAKE_SUPPORT_ROOT)/toolchain.mk

# yea, always forgotten ...
INCLUDE_DIRS := $(INCLUDE_DIRS) -I. 


ifneq ($(INCLUDES),)
INCLUDE_DIRS := $(INCLUDE_DIRS) $(foreach temp, $(INCLUDES), -I$(temp))
else 
	ifneq ($(SUBPROJECTS),)
		INCLUDE_DIRS := $(INCLUDE_DIRS) $(foreach temp, $(SUBPROJECTS), -I$(temp))
	endif
endif

COMMON_FLAGS := $(COMMON_FLAGS) $(INCLUDE_DIRS) $(DEFINES) 

CXXFLAGS := $(CXXFLAGS) $(COMMON_FLAGS) 
CCFLAGS := $(CCFLAGS) $(COMMON_FLAGS) 
ASFLAGS := $(ASFLAGS) $(COMMON_FLAGS)
LDFLAGS := $(LDFLAGS)


CXXCOMMAND := $(CXX) $(CXXFLAGS)
CCCOMMAND := $(CC) $(CCFLAGS)
ASCOMMAND := $(AS) $(ASFLAGS)
CXXDEPCOMMAND := $(CXX_DEP) $(CXXFLAGS)
CCDEPCOMMAND := $(CC_DEP) $(CCFLAGS)
ASDEPCOMMAND := $(AS_DEP) $(ASFLAGS)
LDCOMMAND := $(LD) $(LDFLAGS)


## find out the location where our objects should go


OBJECTDIR := $(subst /sweb-testing/,/sweb-testing-bin/,${PWD})
SOURECDIR := $(PWD)
BINARYDESTDIR := $(subst /sweb-testing/,/sweb-testing-bin/,${PWD}/${PROJECT_ROOT}/bin)

CXXFILES := $(wildcard *.cpp)
CCFILES := $(wildcard *.c)
ASFILES := $(wildcard *.s)

CXXOBJECTS_TEMP := $(patsubst %.cpp,%.o,$(CXXFILES))
CCOBJECTS_TEMP := $(patsubst %.c,%.o,$(CCFILES))
ASOBJECTS_TEMP := $(patsubst %.s,%.o,$(ASFILES))

CXXOBJECTS := $(foreach temp, $(CXXOBJECTS_TEMP), $(OBJECTDIR)/$(temp))
CCOBJECTS := $(foreach temp, $(CCOBJECTS_TEMP), $(OBJECTDIR)/$(temp))
ASOBJECTS := $(foreach temp, $(ASOBJECTS_TEMP), $(OBJECTDIR)/$(temp))

OBJECTS := $(CXXOBJECTS) $(CCOBJECTS) $(ASOBJECTS)

IS_LIB := $(findstring .a,$(TARGET))

TARGET := $(OBJECTDIR)/$(TARGET)

SHARED_LIBS_NEW := $(foreach temp, $(SHARED_LIBS), $(OBJECTDIR)/$(temp))
SHARED_LIBS := $(SHARED_LIBS_NEW) $(SHARED_LIBS_PROJECT)

all: $(TARGET)


## for the sake of simplicity, if we do not have a exe we set subdirs to be empty to 
## avoid an endless recursion


ifeq ($(IS_LIB),)
.PHONY: subdirs $(SUBPROJECTS)

subdirs: $(SUBPROJECTS)

$(SUBPROJECTS):
	@$(SHELL) -c 'cd $@ ; $(MAKE) $(MAKECMDGOALS)'
else
SUBPROJECTS :=
endif

ifneq ($(CXXOBJECTS),)
$(CXXOBJECTS): %.o:
ifeq ($(V),1)
	@echo "$(CXXCOMMAND) -c $< -o $@"
else
	@echo "CXX $<"
endif
	@$(CXXCOMMAND) -c $< -o $@      
endif

ifneq ($(CCOBJECTS),)
$(CCOBJECTS): %.o:
ifeq ($(V),1)
	@echo "$(CCCOMMAND) -c $< -o $@"
else
	@echo "CC $<"
endif
	@$(CCCOMMAND) -c $< -o $@        
endif

ifneq ($(ASOBJECTS),)
$(ASOBJECTS): %.o:
ifeq ($(V),1)
	@echo "$(ASOBJECTS)"
	@echo "$(ASCOMMAND) $< -o $@"
else
	@echo "AS $<"
endif
	@$(ASCOMMAND) $< -o $@        
endif

clean-l:
	@echo "CLEAN $(OBJECTDIR)/*.o"
	@rm -f $(OBJECTDIR)/*.o
	@echo "CLEAN $(TARGET)"
	@rm -f $(TARGET)

clean: $(SUBPROJECTS) clean-l
	
clean-dep-l:
	@echo "CLEAN $(OBJECTDIR)/*.d"
	@rm -f $(OBJECTDIR)/*.d

clean-dep: $(SUBPROJECTS) clean-dep-l
	
mrproper-l: clean-l clean-dep-l

mrproper: $(SUBPROJECTS) mrproper-l


test: 
	@echo "PWD is $(PWD)"
	@echo "TEST is $(OBJECTDIR)"
	@echo "CXXOBJECTS is $(CXXOBJECTS)"
	@echo "TARGET IS $(TARGET)"

ifneq ($(TARGET),)
$(TARGET): $(SUBPROJECTS) $(OBJECTS)
ifneq ($(IS_LIB),)
ifeq ($(V),1)
	@echo "$(AR) rs $(TARGET) $(OBJECTS) 2> /dev/null"
else
	@echo "AR $(TARGET)"
endif
	@mkdir -p $(OBJECTDIR)
	@$(AR) rs $(TARGET) $(OBJECTS) 2> /dev/null
else
ifeq ($(V),1)
	@echo "$(LDCOMMAND) $(OBJECTS)  $(SHARED_LIBS)  -o $(TARGET)"
else
	@echo "LD $(TARGET)"
endif
	@mkdir -p $(OBJECTDIR)
	$(LDCOMMAND) $(OBJECTS)  $(SHARED_LIBS)  -o $(TARGET)
	@echo "Done, copying exe to $(BINARYDESTDIR)/" 
	@mkdir -p $(BINARYDESTDIR)
	cp $(TARGET) $(BINARYDESTDIR)/
endif
endif


depend-l:
	
depend: $(SUBPROJECTS) depend-l



$(OBJECTDIR)%.d: $(SOURECDIR)%.c
ifeq ($(V),1)
	@echo "$(SHELL) -ec 'mkdir -p $(OBJECTDIR) ; $(CCDEPCOMMAND) -DCHANGED -MM $< \
		| awk -f $(PROJECT_MAKE_SUPPORT_ROOT)/gen-dep-helper.awk objectdir=$(OBJECTDIR) depfilename=$@ > $@ ; \
		[ -s $@ ] || rm -f $@ '"	
else
	@echo "DEP $< "
endif
	@$(SHELL) -c 'mkdir -p $(OBJECTDIR) ; $(CCDEPCOMMAND) -DCHANGED -MM $< \
		| awk -f $(PROJECT_MAKE_SUPPORT_ROOT)/gen-dep-helper.awk objectdir=$(OBJECTDIR) depfilename=$@ > $@ ; \
		[ -s $@ ] || rm -f $@ '		

$(OBJECTDIR)%.d: $(SOURECDIR)%.cpp
ifeq ($(V),1)
	@echo "$(SHELL) -c 'mkdir -p $(OBJECTDIR) ; $(CXXDEPCOMMAND) -DCHANGED -MM $< \
		| awk -f $(PROJECT_MAKE_SUPPORT_ROOT)/gen-dep-helper.awk objectdir=$(OBJECTDIR) depfilename=$@ > $@ ; \
		[ -s $@ ] || rm -f $@ '"
else
	@echo "DEP $< "
endif
	@$(SHELL) -c 'mkdir -p $(OBJECTDIR) ; $(CXXDEPCOMMAND) -DCHANGED -MM $< \
		| awk -f $(PROJECT_MAKE_SUPPORT_ROOT)/gen-dep-helper.awk objectdir=$(OBJECTDIR) depfilename=$@ > $@ ; \
		[ -s $@ ] || rm -f $@ '		

#$(OBJECTDIR)%.d: $(SOURECDIR)%.S
#ifeq ($(V),1)
#	@echo "$(SHELL) -c 'mkdir -p $(OBJECTDIR) ; $(ASDEPCOMMAND) -DCHANGED -MM $< \
#		| awk -f $(PROJECT_MAKE_SUPPORT_ROOT)/gen-dep-helper.awk objectdir=$(OBJECTDIR) depfilename=$@ > $@ ; \
#		[ -s $@ ] || rm -f $@ '"
#else
#	@echo "DEP $< "
#endif
#	@$(SHELL) -c 'mkdir -p $(OBJECTDIR) ; $(ASDEPCOMMAND) -DCHANGED -MM $< \
#		| awk -f $(PROJECT_MAKE_SUPPORT_ROOT)/gen-dep-helper.awk objectdir=$(OBJECTDIR) depfilename=$@ > $@ ; \
#		[ -s $@ ] || rm -f $@ '		

$(OBJECTDIR)%.d: $(SOURECDIR)%.s
ifeq ($(V),1)
	@echo "$(SHELL) -c 'mkdir -p $(OBJECTDIR) ; echo \"`echo '$@' | sed s/\.d/\.o/` $@ : $< \" > $@ ;  \
		[ -s $@ ] || rm -f $@ '"
else
	@echo "DEP $< "
endif
	@$(SHELL) -c 'mkdir -p $(OBJECTDIR) ; echo "`echo '$@' | sed s/\.d/\.o/` $@ : $< " > $@ ; \
		[ -s $@ ] || rm -f $@ '		


do-make-dependencies = fubar
ifeq ($(MAKECMDGOALS),clean)
do-make-dependencies =
endif
ifeq ($(MAKECMDGOALS),clean-l)
do-make-dependencies =
endif
ifeq ($(MAKECMDGOALS),clean-dep)
do-make-dependencies =
endif
ifeq ($(MAKECMDGOALS),clean-dep-l)
do-make-dependencies =
endif
ifeq ($(MAKECMDGOALS),mrproper)
do-make-dependencies =
endif
ifeq ($(MAKECMDGOALS),mrproper-l)
do-make-dependencies =
endif

ifneq ($(do-make-dependencies),)
ifneq ($(CXXFILES),)
-include $(foreach temp, $(patsubst %.cpp,%.d,$(CXXFILES)), $(OBJECTDIR)/$(temp)) 
endif
ifneq ($(CCFILES),)
-include $(foreach temp, $(patsubst %.c,%.d,$(CCFILES)), $(OBJECTDIR)/$(temp)) 
endif
ifneq ($(ASFILES),)
-include $(foreach temp, $(patsubst %.s,%.d,$(ASFILES)), $(OBJECTDIR)/$(temp)) 
endif
endif
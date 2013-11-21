# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Template for determining the list of transitive dependencies for a set of java
# source files. As a side-effect of determining the dependencies a jar of the
# compiled java sources is produced.
#
# The including makefile may define these variables:
#   TRANSITIVE_JAVA_DEPS_NAME
#   TRANSITIVE_JAVA_DEPS_ROOT_SOURCES
#     - Fully qualified list of java sources.
#   TRANSITIVE_JAVA_DEPS_SOURCEPATH
#   TRANSITIVE_JAVA_DEPS_JAR_DEPS
#     - Jars that your sources depend on. They'll be added to the classpath.
#   TRANSITIVE_JAVA_DEPS_JAVAC_ARGS
#
# The following variables will be defined by this include:
#   TRANSITIVE_JAVA_DEPS_FULL_SOURCES
#     - Relative list of all java files depended on by the root sources.
#
# Author: Keith Stanger

TRANSITIVE_JAVA_DEPS_JAR = $(BUILD_DIR)/$(TRANSITIVE_JAVA_DEPS_NAME).jar
TRANSITIVE_JAVA_DEPS_INCLUDE = $(BUILD_DIR)/$(TRANSITIVE_JAVA_DEPS_NAME)_transitive.mk
TRANSITIVE_JAVA_DEPS_STAGE_DIR = /tmp/j2objc_$(TRANSITIVE_JAVA_DEPS_NAME)

ifneq ($(findstring clean,$(MAKECMDGOALS)),clean)
ifeq ($(wildcard $(TRANSITIVE_JAVA_DEPS_INCLUDE)),)
# Avoid a warning from the include directive that the file doesn't exist, then
# immediately delete the file so that make rebuilds it correctly.
$(shell mkdir -p $(dir $(TRANSITIVE_JAVA_DEPS_INCLUDE)))
$(shell touch $(TRANSITIVE_JAVA_DEPS_INCLUDE))
include $(TRANSITIVE_JAVA_DEPS_INCLUDE)
$(shell rm $(TRANSITIVE_JAVA_DEPS_INCLUDE))
else
include $(TRANSITIVE_JAVA_DEPS_INCLUDE)
endif
endif

vpath %.java $(TRANSITIVE_JAVA_DEPS_SOURCEPATH)

TRANSITIVE_JAVA_DEPS_JAR_DEPS := $(strip $(TRANSITIVE_JAVA_DEPS_JAR_DEPS))
TRANSITIVE_JAVA_DEPS_CLASSPATH_ARG = \
    $(if $(TRANSITIVE_JAVA_DEPS_JAR_DEPS),-cp $(subst $(space),:,$(TRANSITIVE_JAVA_DEPS_JAR_DEPS)),)
TRANSITIVE_JAVA_DEPS_SOURCEPATH_ARG = \
    $(if $(TRANSITIVE_JAVA_DEPS_SOURCEPATH),-sourcepath $(TRANSITIVE_JAVA_DEPS_SOURCEPATH),)

TRANSITIVE_JAVA_DEPS_JAVAC_CMD =\
    javac $(TRANSITIVE_JAVA_DEPS_SOURCEPATH_ARG) $(TRANSITIVE_JAVA_DEPS_CLASSPATH_ARG)\
    -d $(TRANSITIVE_JAVA_DEPS_STAGE_DIR) $(TRANSITIVE_JAVA_DEPS_JAVAC_ARGS)\
    $(TRANSITIVE_JAVA_DEPS_ROOT_SOURCES)

$(TRANSITIVE_JAVA_DEPS_JAR): \
    $(TRANSITIVE_JAVA_DEPS_ROOT_SOURCES) $(TRANSITIVE_JAVA_DEPS_FULL_SOURCES) \
    $(TRANSITIVE_JAVA_DEPS_JAR_DEPS)
	@mkdir -p $(@D)
	@echo "Building $(notdir $@)"
	@rm -rf $(TRANSITIVE_JAVA_DEPS_STAGE_DIR)
	@mkdir $(TRANSITIVE_JAVA_DEPS_STAGE_DIR)
	$(TRANSITIVE_JAVA_DEPS_JAVAC_CMD)
	@jar cf $@ -C $(TRANSITIVE_JAVA_DEPS_STAGE_DIR) .

$(TRANSITIVE_JAVA_DEPS_INCLUDE): $(TRANSITIVE_JAVA_DEPS_JAR)
	@echo "Building $(notdir $@)"
	@echo "TRANSITIVE_JAVA_DEPS_FULL_SOURCES = \\" > $@
	@jar tf $< | grep \.class$$ | grep -v \\$$ | sed "s/\.class/\.java/" |\
	  sed "s/\(.*\)/  \1 \\\\/" >> $@

# If a java file in the transitive deps has been removed we don't want make to
# fail. We just want the .jar to rebuild.
%.java:
	@:

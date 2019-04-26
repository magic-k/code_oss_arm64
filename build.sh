#!/bin/bash
set -e;

echo "Installing NVM and NodeJS";
. ./setup_nvm.sh;

echo "Retrieving latest Visual Studio Code sources into [code]";
git clone "https://github.com/Microsoft/vscode.git" code;
  
echo "Setting current owner as owner of code folder";
chown ${USER:=$(/usr/bin/id -run)}:$USER -R code;

cd code;
git checkout release/1.33

cd ..;

echo "Synchronizing overlays folder";
rsync -avh ./overlays/ ./code/;

echo "Entering code directory";
cd code;

extra_links="-I$compiler_root_directory/usr/include/libsecret-1 -I$compiler_root_directory/usr/include/glib-2.0 -I$compiler_root_directory/usr/lib/${ARCHIE_HEADERS_GNU_TRIPLET}/glib-2.0/include";
export CC="$CC $extra_links"
export CXX="$CXX $extra_links"

CHILD_CONCURRENCY=1 yarn;

echo "Changing default telemetry settings"
REPLACEMENT="s/'default': true/'default': false/"
sed -i -E "$REPLACEMENT" src/vs/platform/telemetry/common/telemetryService.ts

#echo "Running hygiene";
#npm run gulp -- hygiene;

echo "Running monaco-compile-check";
npm run monaco-compile-check;

# echo "Executing strict-null-check";
# npm run strict-null-check;

echo "Compiling VS Code for $ARCHIE_ELECTRON_ARCH";
npm run gulp -- vscode-linux-$ARCHIE_ELECTRON_ARCH-min --allowEmpty;

echo "Patching resources/linux/debian/postinst.template"
sed -i "s/code-oss/vscodium/" resources/linux/debian/postinst.template

echo "Undoing telemetry"
TELEMETRY_URLS="(dc\.services\.visualstudio\.com)|(vortex\.data\.microsoft\.com)"
REPLACEMENT="s/$TELEMETRY_URLS/0\.0\.0\.0/g"
grep -rl --exclude-dir=.git -E $TELEMETRY_URLS . | xargs sed -i -E $REPLACEMENT

echo "Starting vscode-linux-$ARCHIE_ELECTRON_ARCH-build-deb";
yarn run gulp vscode-linux-$ARCHIE_ELECTRON_ARCH-build-deb;

#echo "Starting vscode-linux-$ARCHIE_ELECTRON_ARCH-build-rpm";
#yarn run gulp vscode-linux-$ARCHIE_ELECTRON_ARCH-build-rpm;

echo "Leaving code directory";
cd ..;

echo "Creating output directory";
mkdir output;

echo "Moving deb packages for release";
mv ./code/.build/linux/deb/$ARCHIE_ARCH/deb/*.deb /root/output;

echo "Moving rpm packages for release";
mv ./code/.build/linux/rpm/$ARCHIE_RPM_ARCH/rpmbuild/RPMS/$ARCHIE_RPM_ARCH/*.rpm /root/output;

echo "Extracting deb archive";
dpkg -x /root/output/*.deb output/extracted;

cd output/extracted;

echo "Binary components of output --------------------------------------------------"
find . -type f -exec file {} ";" | grep ELF
echo "------------------------------------------------------------------------------"

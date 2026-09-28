#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."

platforms=()
created_ios=false
[[ -d android ]] || platforms+=("android")
[[ -d ios ]] || platforms+=("ios")
if (( ${#platforms[@]} )); then
  work="$(mktemp -d)"
  trap 'rm -rf "$work"' EXIT
  for platform in "${platforms[@]}"; do
    flutter create --org com.example --project-name my_app --platforms="$platform" "$work/my_app"
    cp -R "$work/my_app/$platform" .
    [[ "$platform" != ios ]] || created_ios=true
  done
fi



flutter pub get

# Flutter's SDK defaults are replaced once. A concrete value means someone has
# already configured that platform, so repeat runs leave it alone.
if [[ -f android/app/build.gradle.kts ]] && grep -q 'minSdk = flutter.minSdkVersion' android/app/build.gradle.kts; then
  sed -i.bak 's/minSdk = flutter.minSdkVersion/minSdk = 24/' android/app/build.gradle.kts
  rm -f android/app/build.gradle.kts.bak
elif [[ -f android/app/build.gradle ]] && grep -q 'minSdkVersion flutter.minSdkVersion' android/app/build.gradle; then
  sed -i.bak 's/minSdkVersion flutter.minSdkVersion/minSdkVersion 24/' android/app/build.gradle
  rm -f android/app/build.gradle.bak
fi
if [[ "$created_ios" == true && -f ios/Runner.xcodeproj/project.pbxproj ]]; then
  sed -E -i.bak 's/IPHONEOS_DEPLOYMENT_TARGET = [0-9.]+;/IPHONEOS_DEPLOYMENT_TARGET = 15.0;/g' ios/Runner.xcodeproj/project.pbxproj
  rm -f ios/Runner.xcodeproj/project.pbxproj.bak
fi

flutter gen-l10n
flutter pub run build_runner build

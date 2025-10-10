# GitHub Actions CI/CD for Trashifier App

This repository includes automated workflows for building, testing, and releasing the Trashifier Flutter app.

## Workflows Overview

### 1. CI/CD Pipeline (`ci_cd.yml`)
**Triggers:** Push to `main`/`dev` branches, Pull Requests to `main`, Manual releases
**Jobs:**
- **Test**: Runs Flutter tests, code formatting, and analysis
- **Build APK**: Creates release APK for Android
- **Build App Bundle**: Creates AAB file for Play Store
- **Release**: Uploads built files to GitHub releases (only on manual releases)

### 2. Release on Tag (`release.yml`)
**Triggers:** Push of version tags (e.g., `v1.0.0`, `v1.2.3`)
**Jobs:**
- Runs tests
- Builds APK and AAB
- Automatically creates a GitHub release with the built files

### 3. Pull Request Checks (`pr_checks.yml`)
**Triggers:** Pull Requests to `main`/`dev` branches
**Jobs:**
- Code quality checks (formatting, analysis, tests)
- Build verification for multiple platforms
- Automatic PR comments with build status

## How to Use

### Creating a Release

#### Method 1: Using Tags (Recommended)
1. Update your app version in `pubspec.yaml`
2. Commit and push your changes
3. Create and push a version tag:
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```
4. The workflow will automatically:
   - Run tests
   - Build APK and AAB files
   - Create a GitHub release
   - Upload the built files to the release

#### Method 2: Manual Release
1. Go to your repository on GitHub
2. Click "Releases" → "Create a new release"
3. Choose a tag version (create new tag if needed)
4. Add release notes
5. Click "Publish release"
6. The workflow will automatically build and attach the APK/AAB files

### Development Workflow

1. **Feature Development**:
   - Create a feature branch from `dev`
   - Make your changes
   - Create a Pull Request to `dev`
   - The PR checks workflow will run automatically

2. **Code Quality**:
   - All PRs must pass formatting checks: `dart format .`
   - All PRs must pass analysis: `flutter analyze`
   - All PRs must pass tests: `flutter test`

3. **Branch Strategy**:
   - `main`: Production-ready code
   - `dev`: Development branch for new features
   - Feature branches: Individual features/fixes

### Build Artifacts

The workflows generate the following artifacts:

- **APK** (`app-release.apk`): Direct installation file for Android devices
- **AAB** (`app-release.aab`): App Bundle for Google Play Store distribution

### Environment Requirements

The workflows use:
- **Flutter**: 3.24.3 (stable channel)
- **Java**: 17 (Zulu distribution)
- **Runner**: Ubuntu Latest

### Customization

To customize the workflows:

1. **Flutter Version**: Update the `flutter-version` in all workflow files
2. **Branches**: Modify the `branches` arrays in the trigger sections
3. **Build Types**: Add additional build configurations (debug, profile, etc.)
4. **Platforms**: Add iOS, Windows, Linux, or macOS builds
5. **Signing**: Add signing configuration for release builds

### Adding Code Signing (Optional)

For production releases, you may want to add code signing:

1. **Android Signing**:
   - Add your keystore file to repository secrets
   - Modify the build commands to include signing parameters
   - Add signing configuration to `android/app/build.gradle`

2. **Repository Secrets**:
   - `ANDROID_KEYSTORE`: Base64 encoded keystore file
   - `ANDROID_KEYSTORE_PASSWORD`: Keystore password
   - `ANDROID_KEY_ALIAS`: Key alias
   - `ANDROID_KEY_PASSWORD`: Key password

### Troubleshooting

**Common Issues:**

1. **Build Failures**: Check Flutter and dependency versions
2. **Test Failures**: Ensure all tests pass locally before pushing
3. **Permission Issues**: Verify `GITHUB_TOKEN` has proper permissions
4. **Artifact Upload**: Check file paths match build output locations

**Debugging Steps:**

1. Check the workflow logs in the "Actions" tab
2. Run the commands locally to reproduce issues
3. Verify all dependencies are properly declared in `pubspec.yaml`
4. Ensure your Flutter and Dart SDK versions match the workflow

## Next Steps

Consider adding these enhancements:

1. **Automated Testing**: Integration and UI tests
2. **Code Coverage**: Coverage reporting and enforcement
3. **Security Scanning**: Dependency vulnerability checks
4. **Multi-platform Builds**: iOS, Web, Desktop releases
5. **Deployment**: Automatic deployment to app stores
6. **Notifications**: Slack/Discord notifications for releases
# GitHub Workflows

This directory contains GitHub Actions workflows for the dnGLua Binary Module project.

## Workflows

### 🚀 Main Workflows

#### `build.yml` - Main CI/CD Pipeline
- **Triggers**: Push to main/master, pull requests, manual dispatch
- **Jobs**:
  - `build`: Windows build with AOT + Managed versions
  - `build-cross-platform`: Cross-platform managed builds
  - `build-native`: Native library builds on multiple platforms
- **Artifacts**: Uploads `bin-aot/`, `bin-managed/`, and `artifacts/`

#### `release.yml` - Release Automation
- **Triggers**: Git tags (v*)
- **Features**:
  - Builds all variants (AOT, Managed, Native)
  - Creates release archive with README
  - Generates GitHub release automatically
  - Includes comprehensive release notes

#### `pr-check.yml` - Pull Request Validation
- **Triggers**: Pull requests to main/master
- **Jobs**:
  - `build-and-test`: Validates AOT and Managed builds
  - `validate-native`: Validates native library builds
- **Matrix**: Ubuntu and Windows
- **Artifacts**: Short retention (7 days)

#### `scheduled-build.yml` - Health Checks
- **Triggers**: Daily at 2 AM UTC
- **Purpose**: Ensures project builds successfully after changes
- **Matrix**: Ubuntu, Windows, macOS
- **Artifacts**: Scheduled build artifacts

## Features

### ✅ Comprehensive Testing
- **Multi-platform**: Windows, Linux, macOS
- **Build Variants**: AOT, Managed, Native
- **Cross-validation**: PR builds tested on multiple platforms

### 📦 Artifact Management
- **Automatic Uploads**: All build outputs preserved
- **Structured Naming**: Clear artifact names by purpose
- **Retention Policies**: Appropriate retention per workflow type

### 🔄 Caching
- **NuGet Caching**: Faster dependency restoration
- **Platform-specific**: Separate cache keys per OS
- **Hash-based**: Cache invalidation on project changes

### 🚀 Release Automation
- **Tag-based Releases**: Automatic releases on version tags
- **Archive Creation**: Comprehensive release packages
- **Release Notes**: Auto-generated comprehensive notes
- **Multi-variant**: All build types included

## Usage

### Manual Builds
Any workflow can be triggered manually via GitHub's "Actions" tab:
1. Go to Actions → Select workflow
2. Click "Run workflow"
3. Choose branch/parameters if needed
4. Monitor progress in real-time

### Pull Request Process
1. Developer creates PR
2. GitHub automatically runs `pr-check.yml`
3. Builds validated on Ubuntu and Windows
4. Artifacts uploaded for review
5. PR can be merged after validation

### Release Process
1. Developer creates and pushes version tag
2. GitHub triggers `release.yml`
3. All build variants created
4. Release archive generated
5. GitHub release created with notes
6. Users can download complete package

## Configuration

### Environment Variables
- `GITHUB_TOKEN`: Automatically provided for releases
- No additional configuration required

### Customization
- **Build scripts**: Modify `build-module.ps1` and `build-native.ps1`
- **Workflow triggers**: Adjust branches, schedules, or events
- **Artifact paths**: Change upload directories in workflow files
- **Release notes**: Modify release template in `release.yml`

## Troubleshooting

### Build Failures
- Check workflow logs for specific error messages
- Verify build script compatibility
- Ensure .NET SDK version matches requirements

### Artifact Issues
- Confirm files are generated before upload
- Check artifact path configurations
- Verify retention policies

### Release Problems
- Ensure proper tag format (v*)
- Check GITHUB_TOKEN permissions
- Validate release archive contents

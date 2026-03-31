# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2024-03-31

### Added
- Standardized Helm chart structure
- Enhanced helpers template with selectorLabels and metadata helpers
- Separate configuration for Ghost and MySQL resources
- Support for separate storage sizes for Ghost and MySQL
- Pod annotations and security context support
- ServiceAccount creation support
- Proper Helm best practices implementation

### Changed
- Refactored values.yaml with organized sections
- Improved Chart.yaml metadata with maintainers and sources
- Enhanced deployment template with proper labeling
- Removed duplicate labels across resources
- Updated all templates to use helper functions

### Fixed
- Removed hardcoded port values
- Fixed label duplication in ConfigMap and Secrets
- Standardized metadata handling across all resources

## [0.1.0] - Initial Release

### Added
- Initial Helm chart for Ghost CMS with MySQL
- ConfigMap, Secrets, PVC, Deployment, Service, Ingress templates

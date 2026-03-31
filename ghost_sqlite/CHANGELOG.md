# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2024-03-31

### Added
- Standardized Helm chart structure with best practices
- Enhanced helpers template with selectorLabels and standard Kubernetes labels
- ConfigMap for Ghost configuration management
- Support for pod annotations and security contexts
- ServiceAccount creation support
- Comprehensive values.yaml organization

### Changed
- Refactored values.yaml with organized sections
- Improved Chart.yaml metadata with maintainers and sources
- Enhanced deployment template with proper labeling
- Standardized metadata handling across all resources
- Updated ingress with enabled flag

### Fixed
- Removed hardcoded port values
- Removed label duplication across resources
- Standardized label naming conventions

## [0.1.0] - Initial Release

### Added
- Initial Helm chart for Ghost CMS with SQLite
- Templates for Deployment, Service, Ingress, PVC

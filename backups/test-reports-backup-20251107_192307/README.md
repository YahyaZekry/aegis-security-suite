# Test Reports Backup - November 7, 2025

This directory contains redundant test reports that were moved from the main project directories during cleanup on November 7, 2025.

## Files Moved from web-dashboard/ directory:

### API Test Reports (JSON format):
- comprehensive_api_test_report_20251107_162934.json
- comprehensive_api_test_report_20251107_163003.json
- comprehensive_api_test_report_20251107_163153.json
- comprehensive_api_test_report_20251107_163321.json
- comprehensive_api_test_report_20251107_163428.json
- comprehensive_api_test_report_20251107_163456.json
- comprehensive_api_test_report_20251107_163853.json
- comprehensive_api_test_report_20251107_164029.json

### Authentication Test Reports:
- comprehensive_auth_test_report_20251107_165224.json
- comprehensive_authentication_testing_report.md

### Comprehensive Test Reports:
- comprehensive_test_report_20251107_170200.json
- comprehensive_test_report_20251107_170200.md

### UI Test Reports:
- comprehensive_ui_test_report.md
- ui_test_report_20251107_164353.json
- ui_test_report_20251107_164450.json
- ui_test_report_20251107_164536.json

### Dashboard Test Reports:
- dashboard_test_report_20251107_145044.json
- dashboard_test_report_20251107_145110.json

## Files Moved from root directory:

### Integration Test Reports:
- integration_test_report_20251107_165744.json
- integration_test_report_20251107_165854.json
- integration_test_report_20251107_190005.json

## Reason for Cleanup:

These reports were identified as redundant because:

1. **Consolidated Report Exists**: The `dashboard_testing_consolidated_report.md` and `.json` files in the web-dashboard directory contain all the essential information from these individual reports.

2. **Multiple Versions**: Many reports represent multiple runs of the same tests with timestamps, where only the latest results are relevant.

3. **Duplicate Information**: The individual reports contain subsets of information that are fully covered in the consolidated report.

4. **Format Redundancy**: Some reports exist in both JSON and Markdown formats with the same content.

## Retained Reports:

The following reports were kept in their original locations:

- `web-dashboard/dashboard_testing_consolidated_report.md` - Main consolidated report
- `web-dashboard/dashboard_testing_consolidated_report.json` - JSON version of consolidated report

These retained reports serve as the primary reference for all dashboard testing activities.

## Recovery:

If any of these archived reports need to be restored, they can be moved back to their original locations:
- JSON reports should go to `web-dashboard/`
- Integration test reports should go to the project root directory

---

**Backup Created**: November 7, 2025  
**Cleanup Performed By**: Kilo Code  
**Purpose**: Reduce redundancy while preserving essential test information
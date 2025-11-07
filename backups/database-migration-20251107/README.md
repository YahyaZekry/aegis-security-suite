# Database Migration Backups - November 7, 2025

This directory contains database backup files created during the migration process on November 7, 2025.

## Directory Structure

### behavioral_analysis/
Contains backup of the behavioral analysis database (behavioral_data.db):
- `behavioral_data.db.backup.20251107_211753` (111K) - Final backup after migration completion

### incident_response/
Contains backup of the incident response database (incidents.db):
- `incidents.db.backup.20251107_211803` (86K) - Final backup after migration completion

### threat_intelligence/
Contains backup of the threat intelligence database (ioc_database.db):
- `ioc_database.db.backup.20251107_211755` (28M) - Final backup after migration completion

## Migration Process

These backups were created during the database migration process that involved:
1. Schema updates to support new features
2. Data optimization and indexing improvements
3. Security enhancements and encryption updates
4. Performance optimizations

## Backup Strategy

Only the most recent backup file for each database has been preserved to ensure data safety while optimizing storage space. The most recent backup for each database represents the final state after successful migration completion.

## Restoration

If restoration is needed, use the most recent backup file for each database:
- behavioral_analysis: `behavioral_data.db.backup.20251107_211753`
- incident_response: `incidents.db.backup.20251107_211803`
- threat_intelligence: `ioc_database.db.backup.20251107_211755`

## Cleanup Actions

On November 7, 2025, the following cleanup actions were performed:

1. **Initial Organization**: All database backup files were moved from their original locations in the `configs/` directories to this centralized backup location to:
   - Organize backup files in a dedicated location
   - Clean up the configs directories
   - Maintain data safety and recovery options
   - Improve project structure and maintainability

2. **Backup Optimization**: On November 7, 2025 at 22:35 UTC, older backup files were removed to optimize storage space while maintaining data safety:
   - Removed older behavioral_data.db backups (kept only 20251107_211753)
   - Removed older incidents.db backups (kept only 20251107_211803)
   - Removed older ioc_database.db backups (kept only 20251107_211755)
   - Preserved only the most recent backup for each database
   - Maintained proper file permissions (rwxrwxrwx)

Total space used after cleanup: ~28MB (reduced from ~125MB)
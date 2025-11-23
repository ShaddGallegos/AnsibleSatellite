# Ansible Configuration Playbooks - Migration Guide

## Overview

The ansible_configuration playbooks have been completely refactored and consolidated into two comprehensive playbooks with improved error handling, conditional logic, and extensive troubleshooting capabilities.

## Changes Summary

### Old Playbooks (Removed)
- `comms.yml` - 330 lines, mixed responsibilities
- `configure_controller_job.yml` - 178 lines, limited error handling
- `controller_vars.yml` - User-specific configuration (removed from repo)

### New Playbooks (Created)
- `setup_satellite_aap_integration.yml` - 671 lines, comprehensive integration
- `configure_aap_job_templates.yml` - 501 lines, automated template creation
- `controller_vars.yml.example` - Template for user configuration
- `README.md` - Complete documentation with examples

## Key Improvements

### 1. Better Error Handling
**Old Behavior**:
- Failed silently or with minimal error messages
- No retry logic
- No fallback options

**New Behavior**:
- Retry logic with configurable attempts (default: 3-5 retries)
- Detailed error messages with troubleshooting steps
- Graceful fallbacks (e.g., multiple CA cert locations)
- Pre-flight connectivity checks
- Failed_when: false for non-critical operations

### 2. Conditional Logic with "when" Clauses
**Added Throughout**:
```yaml
# Example: Skip if already exists
when: _sat_cert_stat.stat.exists

# Example: Only run on failure
when: _sat_connect is failed

# Example: Multiple conditions
when:
  - _controller_token | length > 0
  - _api_ping is succeeded
```

### 3. Fallback Options
**Implemented**:
- Multiple authentication methods (OAuth, username/password, env vars, interactive)
- Multiple CA certificate search locations
- Service check failures don't stop playbook
- Certificate verification can be disabled (with warnings)
- Auto-installation of missing collections

### 4. Code Consolidation
**Before**: Two separate playbooks with overlapping functionality
**After**: 
- `setup_satellite_aap_integration.yml` - All integration tasks
- `configure_aap_job_templates.yml` - All template creation

**Eliminated Duplication**:
- Certificate export logic (now single implementation)
- API authentication (unified across both playbooks)
- Error message formatting (consistent throughout)
- Configuration validation (centralized in pre_tasks)

### 5. Enhanced Features

#### setup_satellite_aap_integration.yml
**New Features**:
- Service health checks (foreman, httpd, postgresql, pulpcore)
- Multiple CA cert location search
- Automatic CA cert generation fallback
- Connectivity pre-checks before operations
- Idempotent resource creation (safe to re-run)
- Detailed final summary with next steps
- Tag support for partial runs

**Tags Available**:
- `satellite_prep` - Only prepare Satellite
- `aap_config` - Only configure AAP
- `certificates` - Only handle certificates
- `sync` - Only trigger inventory sync

#### configure_aap_job_templates.yml
**New Features**:
- Creates 10 pre-configured job templates (vs 1 before)
- Multiple authentication methods
- Auto-loads controller_vars.yml if present
- Interactive credential prompting
- Auto-installs ansible.controller collection
- Pre-flight API connectivity test
- Detailed success/failure reporting

**Job Templates Created**:
1. Build Nodes in Batches
2. Create Single PXE Node
3. Bulk Create PXE Nodes
4. Delete PXE Node
5. List PXE Nodes
6. PXE Boot Remediation
7. Satellite Health Check
8. Backup Satellite Configuration
9. Cleanup Orphaned Disks

## Migration Steps

### For Existing Users

**Step 1**: Review your current usage
```bash
# Check if you have customizations in old playbooks
grep -n "CUSTOM\|TODO\|FIXME" comms.yml configure_controller_job.yml
```

**Step 2**: Backup existing configuration
```bash
# Save your controller_vars.yml if it exists
cp controller_vars.yml controller_vars.yml.backup
```

**Step 3**: Create new configuration
```bash
# Copy example file
cp controller_vars.yml.example controller_vars.yml
chmod 600 controller_vars.yml

# Edit with your settings (refer to backup if needed)
vi controller_vars.yml
```

**Step 4**: Test new playbooks
```bash
# Test Satellite integration (read-only tags first)
ansible-playbook -i inventory setup_satellite_aap_integration.yml \
  --tags connectivity,health_check

# Test AAP configuration with one template
ansible-playbook configure_aap_job_templates.yml --check
```

**Step 5**: Full migration
```bash
# Run complete integration setup
ansible-playbook -i inventory setup_satellite_aap_integration.yml

# Configure all job templates
ansible-playbook configure_aap_job_templates.yml
```

### Configuration File Migration

**Old controller_vars.yml**:
```yaml
controller_host: "https://ansible.prod.spg"
controller_oauthtoken: "TOKEN"
organization_name: "Default"
project_name: "AnsibleLaunchPad"
job_template_name: "Build Nodes in Batches"
job_playbook_path: "AnsibleSatellite/build_nodes_in_batches.yml"
```

**New controller_vars.yml** (enhanced):
```yaml
controller_host: "https://ansible.prod.spg"
controller_oauthtoken: "TOKEN"
controller_verify_ssl: false
organization_name: "Default"
project_name: "AnsibleLaunchPad"
inventory_name: "Satellite Inventory"
credential_name: ""
execution_environment: ""
api_retry_count: 3
api_retry_delay: 5
```

**Changes**:
- Removed template-specific settings (now in playbook)
- Added `inventory_name` (required)
- Added `controller_verify_ssl` for cert control
- Added retry configuration
- Added optional credential and EE settings

## Behavior Changes

### Authentication
**Old**: Only OAuth token supported
**New**: Multiple methods with priority:
1. OAuth token (recommended)
2. Username/password
3. Environment variables
4. Interactive prompt

### Error Handling
**Old**: Playbook stopped on first error
**New**: Graceful degradation with warnings

### Certificate Management
**Old**: Failed if cert not in exact location
**New**: Searches multiple locations, generates if needed

### API Operations
**Old**: Single attempt, fail immediately
**New**: Configurable retries with delays

## Testing Checklist

After migration, verify:

- Satellite connectivity test passes
- CA certificates exported correctly
- AAP API authentication succeeds
- Credential type discovered
- Satellite credential created/updated
- Satellite inventory created/updated
- Inventory source created/updated
- Inventory sync triggers successfully
- All 10 job templates created
- Survey questions configured correctly
- Templates visible in AAP UI
- Test template execution works

## Rollback Plan

If issues occur, you can temporarily use old playbooks:

```bash
# Restore from git history
git checkout HEAD~1 -- playbooks/ansible_configuration/comms.yml
git checkout HEAD~1 -- playbooks/ansible_configuration/configure_controller_job.yml

# Run old playbooks
ansible-playbook -i inventory comms.yml
ansible-playbook configure_controller_job.yml
```

## Troubleshooting

### Issue: New playbook fails but old one worked

**Solution**: Enable debug mode
```bash
ansible-playbook playbook.yml -vvv
```

### Issue: Authentication fails

**Solution**: Verify credentials
```bash
# Test Satellite
curl -k -u admin:password https://satellite.prod.spg/api/v2/ping

# Test AAP
curl -k -u admin:password https://ansible.prod.spg/api/controller/v2/ping/
```

### Issue: Certificate verification fails

**Solution**: Temporarily disable (lab only)
```bash
ansible-playbook setup_satellite_aap_integration.yml \
  -e verify_certificates=false

ansible-playbook configure_aap_job_templates.yml \
  -e controller_verify_ssl=false
```

## Support

For issues or questions:
1. Check `README.md` in ansible_configuration directory
2. Review playbook comments and task names
3. Run with `-vvv` for detailed output
4. Check AAP/Satellite logs for API errors

## Version Information

- **Old Version**: 1.0 (separate comms.yml and configure_controller_job.yml)
- **New Version**: 2.0 (consolidated setup_satellite_aap_integration.yml and configure_aap_job_templates.yml)
- **Migration Date**: November 20, 2025
- **Breaking Changes**: Configuration file format (minor), authentication methods (enhanced)

# Quick Reference - Ansible Configuration Playbooks

## Files Overview

| File | Purpose | Size |
|------|---------|------|
| `setup_satellite_aap_integration.yml` | Complete Satellite-AAP integration | 24K, 671 lines |
| `configure_aap_job_templates.yml` | Create 10 AAP job templates | 18K, 501 lines |
| `controller_vars.yml.example` | Configuration template | 1.9K, 57 lines |
| `README.md` | Full documentation | 15K, 482 lines |
| `MIGRATION.md` | Upgrade guide | 8.1K, 271 lines |

## Quick Start

### 1. Satellite-AAP Integration
```bash
# Create env.conf
cat > ~/.ansible/conf/env.conf <<EOF
SATELLITE_HOST_FQDN=satellite.prod.spg
ANSIBLE_HOST_FQDN=ansible.prod.spg
SATELLITE_API_USER=admin
SATELLITE_API_PASSWORD=your_password
AAP_API_USER=admin
AAP_API_PASSWORD=your_password
EOF
chmod 600 ~/.ansible/conf/env.conf

# Run integration (idempotent, safe to re-run)
ansible-playbook -i inventory setup_satellite_aap_integration.yml
```

### 2. Configure Job Templates
```bash
# Setup credentials
cp controller_vars.yml.example controller_vars.yml
chmod 600 controller_vars.yml
# Edit with your AAP details

# Create all 10 job templates
ansible-playbook configure_aap_job_templates.yml
```

## Common Commands

### Partial Runs (Tags)
```bash
# Only check connectivity
ansible-playbook setup_satellite_aap_integration.yml --tags connectivity

# Only handle certificates
ansible-playbook setup_satellite_aap_integration.yml --tags certificates

# Only sync inventory
ansible-playbook setup_satellite_aap_integration.yml --tags sync

# Satellite prep only
ansible-playbook setup_satellite_aap_integration.yml --tags satellite_prep

# AAP config only
ansible-playbook setup_satellite_aap_integration.yml --tags aap_config
```

### Troubleshooting
```bash
# Verbose mode
ansible-playbook playbook.yml -vvv

# Disable certificate verification (lab only)
ansible-playbook setup_satellite_aap_integration.yml -e verify_certificates=false
ansible-playbook configure_aap_job_templates.yml -e controller_verify_ssl=false

# Custom retry settings
ansible-playbook configure_aap_job_templates.yml -e api_retry_count=10 -e api_retry_delay=10
```

### Authentication Options

**OAuth Token** (recommended):
```bash
ansible-playbook configure_aap_job_templates.yml -e controller_oauthtoken=YOUR_TOKEN
```

**Username/Password**:
```bash
ansible-playbook configure_aap_job_templates.yml \
  -e controller_username=admin \
  -e controller_password=secret
```

**Environment Variables**:
```bash
export CONTROLLER_OAUTH_TOKEN=YOUR_TOKEN
ansible-playbook configure_aap_job_templates.yml
```

**Interactive** (no credentials = prompt):
```bash
ansible-playbook configure_aap_job_templates.yml
# Will prompt for username and password
```

## Job Templates Created

| # | Template Name | Purpose |
|---|---------------|---------|
| 1 | Build Nodes in Batches | Multi-batch node creation (5 per batch) |
| 2 | Create Single PXE Node | Individual node creation |
| 3 | Bulk Create PXE Nodes | Consecutive node creation with auto-slots |
| 4 | Delete PXE Node | Node removal and cleanup |
| 5 | List PXE Nodes | Display inventory and available slots |
| 6 | PXE Boot Remediation | Fix boot files and troubleshoot |
| 7 | Satellite Health Check | Service and API validation |
| 8 | Backup Satellite Configuration | Config backup to tar.gz |
| 9 | Cleanup Orphaned Disks | Remove orphaned VM volumes |

## Key Improvements

- **Error Handling**: Retry logic (3-5 attempts), detailed error messages
- **Conditionals**: 45+ "when" clauses for smart execution
- **Fallbacks**: Multiple auth methods, cert locations, graceful degradation
- **Consolidation**: Eliminated code duplication
- **Tags**: 6 tag groups for partial execution
- **Health Checks**: 6 Satellite services monitored
- **Idempotent**: Safe to re-run without side effects
- **Documentation**: 753 lines of docs (README + MIGRATION)

## Variables Reference

### setup_satellite_aap_integration.yml
| Variable | Default | Purpose |
|----------|---------|---------|
| `env_conf_path` | `~/.ansible/conf/env.conf` | Config file location |
| `verify_certificates` | `false` | Enable/disable cert verification |
| `organization_id` | `1` | AAP organization ID |
| `api_retry_count` | `5` | API call retry attempts |
| `api_retry_delay` | `5` | Seconds between retries |

### configure_aap_job_templates.yml
| Variable | Default | Purpose |
|----------|---------|---------|
| `controller_host` | Required | AAP Controller URL |
| `controller_oauthtoken` | `""` | OAuth token (preferred) |
| `controller_username` | `""` | Username (fallback) |
| `controller_password` | `""` | Password (fallback) |
| `controller_verify_ssl` | `true` | SSL verification |
| `organization_name` | `"Default"` | AAP organization |
| `project_name` | `"AnsibleLaunchPad"` | Git project name |
| `inventory_name` | `"Satellite Inventory"` | Target inventory |
| `api_retry_count` | `3` | Retry attempts |

## Verification Tests

```bash
# Test Satellite connectivity
curl -k -u admin:password https://satellite.prod.spg/api/v2/ping

# Test AAP connectivity
curl -k https://ansible.prod.spg/api/controller/v2/ping/

# Verify certificates exported
ls -lh /etc/pki/ca-trust/source/anchors/satellite-ca.crt
ls -lh /etc/pki/ca-trust/source/anchors/aap-ca.crt

# Check AAP resources created
curl -k -u admin:password https://ansible.prod.spg/api/controller/v2/credentials/ | jq
curl -k -u admin:password https://ansible.prod.spg/api/controller/v2/inventories/ | jq
curl -k -u admin:password https://ansible.prod.spg/api/controller/v2/job_templates/ | jq
```

## Migration from Old Playbooks

**Old to New** mapping:
- `comms.yml` (330 lines) to `setup_satellite_aap_integration.yml` (671 lines)
- `configure_controller_job.yml` (178 lines) to `configure_aap_job_templates.yml` (501 lines)

See `MIGRATION.md` for detailed upgrade instructions.

## Support

**Documentation**: 
- Full guide: `README.md`
- Migration: `MIGRATION.md`
- This reference: `QUICK_REFERENCE.md`

**Logs**:
```bash
# AAP logs
journalctl -u automation-controller -f

# Satellite logs
tail -f /var/log/foreman/production.log
```

**Help**:
- Run with `-vvv` for verbose output
- Check error messages for troubleshooting hints
- Review pre_tasks for validation failures

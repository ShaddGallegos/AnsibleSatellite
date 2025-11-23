# Ansible Configuration Playbooks

Consolidated playbooks for configuring Ansible Automation Platform (AAP) and integrating with Red Hat Satellite.

## Overview

This directory contains two main playbooks:

1. **setup_satellite_aap_integration.yml** - Complete integration setup between Satellite and AAP
2. **configure_aap_job_templates.yml** - Automated job template creation with surveys

## Playbooks

### 1. setup_satellite_aap_integration.yml

**Purpose**: Comprehensive setup of Satellite and AAP integration including certificate trust, API configuration, and inventory sync.

**Features**:
- Satellite connectivity verification with retry logic
- Automatic CA certificate discovery and export
- Multiple CA cert location fallback
- Service health checks
- AAP API authentication with token management
- Credential type auto-discovery
- Idempotent resource creation (credentials, inventories, sources)
- Automatic inventory sync trigger
- Comprehensive error handling with troubleshooting hints
- Certificate verification options (can be disabled)

**Requirements**:
- SSH access to Satellite server (root)
- Configuration file: `env.conf` with required variables
- Network connectivity between control node and both Satellite/AAP

**Configuration File** (`env.conf`):
```ini
SATELLITE_HOST_FQDN=satellite.prod.spg
ANSIBLE_HOST_FQDN=ansible.prod.spg
SATELLITE_API_USER=admin
SATELLITE_API_PASSWORD=your_password
AAP_API_USER=admin
AAP_API_PASSWORD=your_password
```

**Usage**:
```bash
# With default env.conf location (~/.ansible/conf/env.conf)
ansible-playbook -i inventory setup_satellite_aap_integration.yml

# With custom env.conf location
export ANSIBLE_ENV_CONF=/path/to/env.conf
ansible-playbook -i inventory setup_satellite_aap_integration.yml

# Or via extra vars
ansible-playbook -i inventory setup_satellite_aap_integration.yml \
  -e env_conf_path=/custom/path/env.conf

# Run only specific tags
ansible-playbook -i inventory setup_satellite_aap_integration.yml \
  --tags certificates,aap_api

# Skip certificate verification (troubleshooting)
ansible-playbook -i inventory setup_satellite_aap_integration.yml \
  -e verify_certificates=false
```

**Available Tags**:
- `satellite_prep` - Satellite server preparation
- `connectivity` - SSH connectivity tests
- `ca_cert` - CA certificate operations
- `health_check` - Service health verification
- `aap_config` - AAP configuration tasks
- `integration` - Integration setup
- `packages` - Package installation
- `certificates` - Certificate export and trust
- `inventory_plugin` - Foreman inventory plugin config
- `aap_api` - AAP API operations
- `sync` - Inventory sync trigger

**What It Does**:

**Phase 1 - Satellite Preparation**:
1. Establishes SSH connection to Satellite with retry logic
2. Searches for CA certificate in multiple standard locations
3. Generates CA cert if not found using katello-certs-check
4. Verifies Satellite services are running (foreman, httpd, postgresql, pulpcore)

**Phase 2 - AAP Integration**:
1. Reads and validates configuration from env.conf
2. Installs required packages (python3-requests, ca-certificates, openssl)
3. Tests connectivity to Satellite and AAP servers
4. Exports certificate chains from both servers
5. Updates system CA trust store
6. Configures foreman.yml inventory plugin
7. Authenticates to AAP API and creates token
8. Discovers Red Hat Satellite credential type
9. Creates/updates Satellite API credential (idempotent)
10. Creates/updates Satellite inventory (idempotent)
11. Creates/updates inventory source with auto-sync (idempotent)
12. Triggers initial inventory sync
13. Provides detailed summary and troubleshooting info

**Error Handling**:
- Graceful fallback for missing certificates
- Connectivity checks with helpful error messages
- API retry logic with configurable attempts
- Idempotent operations (safe to re-run)
- Detailed troubleshooting output on failures

**Inventory Requirements**:
```ini
[satellite]
satellite.prod.spg ansible_user=root

[localhost]
127.0.0.1 ansible_connection=local
```

---

### 2. configure_aap_job_templates.yml

**Purpose**: Automated creation of AAP Controller job templates with surveys for all major playbooks in the project.

**Features**:
- Multiple authentication methods (OAuth token, username/password, env vars, interactive)
- Auto-loads controller_vars.yml if present
- API connectivity pre-flight check
- Automatic ansible.controller collection installation
- Creates 10 pre-configured job templates with surveys
- Comprehensive error handling and troubleshooting
- Detailed success/failure reporting
- Support for self-signed certificates

**Pre-configured Job Templates**:
1. **Build Nodes in Batches** - Multi-batch node creation (5 nodes per batch)
2. **Create Single PXE Node** - Individual node creation
3. **Bulk Create PXE Nodes** - Consecutive node creation with auto-slot allocation
4. **Delete PXE Node** - Node removal and cleanup
5. **List PXE Nodes** - Inventory display
6. **PXE Boot Remediation** - Boot file resolution and troubleshooting
7. **Satellite Health Check** - Comprehensive health validation
8. **Backup Satellite Configuration** - Config backup
9. **Cleanup Orphaned Disks** - Libvirt disk cleanup

**Authentication Methods** (in priority order):

1. **OAuth Token** (recommended):
```bash
# Via extra vars
ansible-playbook configure_aap_job_templates.yml -e controller_oauthtoken=YOUR_TOKEN

# Via environment variable
export CONTROLLER_OAUTH_TOKEN=YOUR_TOKEN
ansible-playbook configure_aap_job_templates.yml
```

2. **Username/Password**:
```bash
# Via extra vars
ansible-playbook configure_aap_job_templates.yml \
  -e controller_username=admin \
  -e controller_password=secret

# Via environment variables
export CONTROLLER_USERNAME=admin
export CONTROLLER_PASSWORD=secret
ansible-playbook configure_aap_job_templates.yml
```

3. **controller_vars.yml file**:
```bash
# Copy example file and customize
cp controller_vars.yml.example controller_vars.yml
chmod 600 controller_vars.yml
# Edit with your credentials
ansible-playbook configure_aap_job_templates.yml
```

4. **Interactive Prompt**:
```bash
# Run without credentials - will prompt
ansible-playbook configure_aap_job_templates.yml
```

**Usage Examples**:

```bash
# Using controller_vars.yml (recommended for repeated use)
cp controller_vars.yml.example controller_vars.yml
# Edit controller_vars.yml with your settings
ansible-playbook configure_aap_job_templates.yml

# Using OAuth token
ansible-playbook configure_aap_job_templates.yml \
  -e controller_host=https://aap.example.com \
  -e controller_oauthtoken=YOUR_TOKEN \
  -e organization_name="Default" \
  -e project_name="AnsibleLaunchPad" \
  -e inventory_name="Satellite Inventory"

# Using username/password with custom settings
ansible-playbook configure_aap_job_templates.yml \
  -e controller_host=https://aap.example.com \
  -e controller_username=admin \
  -e controller_password=secret \
  -e controller_verify_ssl=false \
  -e organization_name="Production" \
  -e project_name="Infrastructure"

# Using environment variables
export CONTROLLER_HOST=https://aap.example.com
export CONTROLLER_OAUTH_TOKEN=YOUR_TOKEN
ansible-playbook configure_aap_job_templates.yml
```

**Required Variables**:
- `controller_host` - AAP Controller URL
- `organization_name` - AAP organization name
- `project_name` - Project containing playbooks
- `inventory_name` - Inventory to use for job templates

**Optional Variables**:
- `credential_name` - Machine credential for SSH access
- `execution_environment` - Specific EE to use
- `controller_verify_ssl` - Certificate verification (default: true)
- `api_retry_count` - API retry attempts (default: 3)
- `api_retry_delay` - Seconds between retries (default: 5)

**What It Does**:
1. Loads controller_vars.yml if present
2. Normalizes authentication from multiple sources
3. Tests AAP API connectivity with retries
4. Validates required configuration
5. Ensures ansible.controller collection is available
6. Creates/updates 10 job templates with surveys
7. Provides detailed success/failure report

**Generating OAuth Token in AAP**:
1. Log into AAP web UI
2. Navigate to: Administration > Users > [Your Username] > Tokens
3. Click "Add" to create new token
4. Set scope to "Write"
5. Copy token immediately (shown only once)

**Troubleshooting**:

**Connection refused / timeout**:
```bash
# Test connectivity manually
curl -k https://aap.example.com/api/controller/v2/ping/

# Use retry with custom count
ansible-playbook configure_aap_job_templates.yml \
  -e api_retry_count=10 \
  -e api_retry_delay=10
```

**Certificate verification errors**:
```bash
# Disable SSL verification (lab only)
ansible-playbook configure_aap_job_templates.yml \
  -e controller_verify_ssl=false
```

**Authentication failures**:
```bash
# Verify credentials work with curl
curl -k -u admin:password https://aap.example.com/api/controller/v2/me/

# Use interactive prompt to re-enter
ansible-playbook configure_aap_job_templates.yml
# Will prompt for username/password
```

**Collection not found**:
```bash
# Install manually
ansible-galaxy collection install ansible.controller

# Or let playbook auto-install
ansible-playbook configure_aap_job_templates.yml
# Playbook will attempt auto-install
```

---

## Configuration Files

### controller_vars.yml (user-created)

Copy from `controller_vars.yml.example` and customize:
```bash
cp controller_vars.yml.example controller_vars.yml
chmod 600 controller_vars.yml
```

**Security**: This file contains credentials. Add to `.gitignore`:
```bash
echo "controller_vars.yml" >> .gitignore
```

### controller_vars.yml.example (template)

Template file with all available variables and documentation. Safe to commit to version control.

---

## Workflow Examples

### Initial Setup Workflow

**Step 1**: Set up Satellite-AAP integration
```bash
# Create env.conf with credentials
cat > ~/.ansible/conf/env.conf <<EOF
SATELLITE_HOST_FQDN=satellite.prod.spg
ANSIBLE_HOST_FQDN=ansible.prod.spg
SATELLITE_API_USER=admin
SATELLITE_API_PASSWORD=your_password
AAP_API_USER=admin
AAP_API_PASSWORD=your_password
EOF
chmod 600 ~/.ansible/conf/env.conf

# Run integration setup
ansible-playbook -i inventory setup_satellite_aap_integration.yml
```

**Step 2**: Configure job templates
```bash
# Create controller vars
cp controller_vars.yml.example controller_vars.yml
# Edit with your AAP settings
ansible-playbook configure_aap_job_templates.yml
```

**Step 3**: Verify in AAP UI
1. Log into AAP: https://ansible.prod.spg
2. Navigate to: Resources > Templates
3. Verify 10 templates created
4. Test a template (e.g., "List PXE Nodes")

### Re-run After Changes

Both playbooks are idempotent and safe to re-run:

```bash
# Re-sync inventory after Satellite changes
ansible-playbook -i inventory setup_satellite_aap_integration.yml --tags sync

# Update job templates after playbook changes
ansible-playbook configure_aap_job_templates.yml
```

---

## Dependencies

### Python Packages
- `python3-requests` - HTTP client for API calls
- `ansible.controller` collection - AAP automation

### Ansible Collections
- `ansible.controller` - AAP Controller modules
- `redhat.satellite` (optional) - Satellite inventory plugin

Install collections:
```bash
ansible-galaxy collection install ansible.controller
ansible-galaxy collection install redhat.satellite
```

---

## Common Issues and Solutions

### Issue: env.conf not found
**Solution**: Create env.conf or set ANSIBLE_ENV_CONF environment variable
```bash
export ANSIBLE_ENV_CONF=/path/to/env.conf
```

### Issue: Satellite CA certificate not found
**Solution**: Playbook will search multiple locations and attempt generation. If fails, manually copy:
```bash
scp root@satellite:/etc/pki/katello/certs/katello-server-ca.crt /tmp/
```

### Issue: AAP API authentication fails
**Solution**: 
1. Verify credentials in env.conf or controller_vars.yml
2. Generate new OAuth token in AAP UI
3. Check user has appropriate permissions (Organization Admin or System Administrator)

### Issue: Certificate verification errors
**Solution**: For lab environments, disable verification:
```bash
-e verify_certificates=false
-e controller_verify_ssl=false
```

### Issue: ansible.controller collection missing
**Solution**: Install collection or let playbook auto-install:
```bash
ansible-galaxy collection install ansible.controller
```

### Issue: Job templates fail to create
**Solution**:
1. Verify project name matches in AAP
2. Check playbook paths are correct
3. Ensure inventory exists in AAP
4. Verify organization permissions

---

## Security Best Practices

1. **Credentials**:
   - Keep env.conf and controller_vars.yml chmod 600
   - Add to .gitignore
   - Use OAuth tokens instead of passwords when possible
   - Rotate tokens regularly

2. **Certificates**:
   - Use certificate verification in production (`verify_certificates: true`)
   - Only disable for lab environments
   - Keep CA certificates up to date

3. **API Access**:
   - Use least-privilege service accounts
   - Set token expiration policies
   - Monitor API access logs

4. **Network**:
   - Use TLS/HTTPS for all API communication
   - Restrict firewall rules to specific hosts
   - Use VPN or bastion hosts for remote access

---

## Support and Troubleshooting

**Playbook Errors**: Run with verbose mode
```bash
ansible-playbook playbook.yml -vvv
```

**API Issues**: Check AAP logs
```bash
# On AAP server
journalctl -u automation-controller -f
```

**Satellite Issues**: Check Satellite logs
```bash
# On Satellite server
tail -f /var/log/foreman/production.log
```

**Network Issues**: Test connectivity
```bash
# Test Satellite
curl -k -u admin:password https://satellite.prod.spg/api/v2/ping

# Test AAP
curl -k https://ansible.prod.spg/api/controller/v2/ping/
```

---

## Migration from Old Playbooks

The old playbooks (`comms.yml` and `configure_controller_job.yml`) have been replaced with improved versions:

**Old to New**:
- `comms.yml` to `setup_satellite_aap_integration.yml` (Phase 1 & 2 combined)
- `configure_controller_job.yml` to `configure_aap_job_templates.yml` (enhanced with 10 templates)

**Improvements**:
- Better error handling with retries
- Conditional logic with fallbacks
- Multiple authentication methods
- Comprehensive troubleshooting output
- Idempotent operations
- Certificate verification options
- Service health checks
- Auto-discovery of resources
- Detailed logging and reporting
- Tag support for partial runs

---

## Ansible Automation Platform 2.6 Survey Specifications

These playbooks are designed for AAP 2.6. Below are the survey specifications for creating job templates.

### Survey 1: Satellite-AAP Integration Setup

For job template using `setup_satellite_aap_integration.yml`

| Question | Variable Name | Type | Default | Required | Choices |
|----------|--------------|------|---------|----------|----------|
| Environment Config Path | env_conf_path | Text | ~/.ansible/conf/env.conf | No | |
| Verify SSL Certificates | verify_certificates | Multiple Choice | true | No | true, false |
| Satellite Hostname | satellite_host | Text | | No | |
| AAP Hostname | aap_host | Text | | No | |
| Satellite Username | satellite_user | Text | admin | No | |
| Satellite Password | satellite_password | Password | | No | |
| AAP Username | aap_user | Text | admin | No | |
| AAP Password | aap_password | Password | | No | |
| Inventory Name | inventory_name | Text | Satellite Inventory | No | |
| Organization Name | organization_name | Text | Default | No | |

**Survey JSON for AAP 2.6:**
```json
{
  "name": "Satellite-AAP Integration Setup",
  "description": "Configure integration between Satellite and AAP Controller",
  "spec": [
    {
      "question_name": "Environment Config Path",
      "question_description": "Path to env.conf file with credentials",
      "required": false,
      "type": "text",
      "variable": "env_conf_path",
      "default": "~/.ansible/conf/env.conf"
    },
    {
      "question_name": "Verify SSL Certificates",
      "question_description": "Enable SSL certificate verification",
      "required": false,
      "type": "multiplechoice",
      "variable": "verify_certificates",
      "choices": ["true", "false"],
      "default": "true"
    },
    {
      "question_name": "Satellite Hostname",
      "question_description": "Satellite server FQDN (overrides env.conf)",
      "required": false,
      "type": "text",
      "variable": "satellite_host"
    },
    {
      "question_name": "AAP Hostname",
      "question_description": "AAP Controller FQDN (overrides env.conf)",
      "required": false,
      "type": "text",
      "variable": "aap_host"
    },
    {
      "question_name": "Inventory Name",
      "question_description": "Name for Satellite inventory in AAP",
      "required": false,
      "type": "text",
      "variable": "inventory_name",
      "default": "Satellite Inventory"
    },
    {
      "question_name": "Organization Name",
      "question_description": "AAP organization name",
      "required": false,
      "type": "text",
      "variable": "organization_name",
      "default": "Default"
    }
  ]
}
```

### Survey 2: AAP Job Template Configuration

For job template using `configure_aap_job_templates.yml`

| Question | Variable Name | Type | Default | Required | Choices |
|----------|--------------|------|---------|----------|----------|
| Controller Host URL | controller_host | Text | https://ansible.prod.spg | Yes | |
| Controller OAuth Token | controller_oauthtoken | Password | | No* | |
| Controller Username | controller_username | Text | admin | No* | |
| Controller Password | controller_password | Password | | No* | |
| Organization Name | organization_name | Text | Default | Yes | |
| Project Name | project_name | Text | AnsibleLaunchPad | Yes | |
| Inventory Name | inventory_name | Text | Satellite Inventory | Yes | |
| Credential Name | credential_name | Text | Satellite SSH | No | |
| Execution Environment | execution_environment | Text | | No | |
| Verify SSL | controller_verify_ssl | Multiple Choice | true | No | true, false |
| API Retry Count | api_retry_count | Integer | 3 | No | |
| API Retry Delay | api_retry_delay | Integer | 5 | No | |

*Either OAuth token OR username/password required

**Survey JSON for AAP 2.6:**
```json
{
  "name": "AAP Job Template Configuration",
  "description": "Create and configure AAP job templates with surveys",
  "spec": [
    {
      "question_name": "Controller Host URL",
      "question_description": "Full URL to AAP Controller (e.g., https://aap.example.com)",
      "required": true,
      "type": "text",
      "variable": "controller_host",
      "default": "https://ansible.prod.spg"
    },
    {
      "question_name": "Controller OAuth Token",
      "question_description": "OAuth token for authentication (preferred method)",
      "required": false,
      "type": "password",
      "variable": "controller_oauthtoken"
    },
    {
      "question_name": "Controller Username",
      "question_description": "Username for authentication (if not using token)",
      "required": false,
      "type": "text",
      "variable": "controller_username",
      "default": "admin"
    },
    {
      "question_name": "Controller Password",
      "question_description": "Password for authentication (if not using token)",
      "required": false,
      "type": "password",
      "variable": "controller_password"
    },
    {
      "question_name": "Organization Name",
      "question_description": "AAP organization name",
      "required": true,
      "type": "text",
      "variable": "organization_name",
      "default": "Default"
    },
    {
      "question_name": "Project Name",
      "question_description": "Name of project containing playbooks",
      "required": true,
      "type": "text",
      "variable": "project_name",
      "default": "AnsibleLaunchPad"
    },
    {
      "question_name": "Inventory Name",
      "question_description": "Inventory to assign to job templates",
      "required": true,
      "type": "text",
      "variable": "inventory_name",
      "default": "Satellite Inventory"
    },
    {
      "question_name": "Credential Name",
      "question_description": "Machine credential for SSH access",
      "required": false,
      "type": "text",
      "variable": "credential_name",
      "default": "Satellite SSH"
    },
    {
      "question_name": "Verify SSL",
      "question_description": "Enable SSL certificate verification",
      "required": false,
      "type": "multiplechoice",
      "variable": "controller_verify_ssl",
      "choices": ["true", "false"],
      "default": "true"
    },
    {
      "question_name": "API Retry Count",
      "question_description": "Number of API retry attempts",
      "required": false,
      "type": "integer",
      "variable": "api_retry_count",
      "default": 3,
      "min": 1,
      "max": 10
    },
    {
      "question_name": "API Retry Delay",
      "question_description": "Seconds between retry attempts",
      "required": false,
      "type": "integer",
      "variable": "api_retry_delay",
      "default": 5,
      "min": 1,
      "max": 60
    }
  ]
}
```

### Creating Job Templates in AAP 2.6

1. Navigate to **Resources** > **Templates** > **Add** > **Add job template**

2. Fill in basic information:
   - **Name**: "Satellite-AAP Integration" or "Configure AAP Job Templates"
   - **Job Type**: Run
   - **Inventory**: Your inventory
   - **Project**: Your Git project
   - **Playbook**: Select the appropriate playbook
   - **Credentials**: SSH credential for satellite group

3. Under **Survey**:
   - Enable **Survey**
   - Click **Add** to add survey questions
   - Use the tables above or import JSON

4. **Save** the template

### Running Job Templates in AAP 2.6

**Via Web UI:**
1. Navigate to **Resources** > **Templates**
2. Click launch icon next to template
3. Fill in survey form
4. Click **Launch**

**Via API:**
```bash
curl -X POST https://aap-controller/api/v2/job_templates/ID/launch/ \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "extra_vars": {
      "organization_name": "Default",
      "project_name": "AnsibleLaunchPad"
    }
  }'
```

**Via awx CLI:**
```bash
awx job_templates launch \
  --name "Satellite-AAP Integration" \
  --extra-vars '{"verify_certificates": "false"}'
```

---

## Version History

- **v2.0** (Current) - Consolidated playbooks with enhanced error handling, fallbacks, comprehensive documentation, and AAP 2.6 survey specifications
- **v1.0** - Original separate playbooks (comms.yml, configure_controller_job.yml)

# Satellite Configuration Playbooks

Comprehensive Red Hat Satellite configuration automation compatible with Ansible Automation Platform 2.6.

## Overview

This directory contains three consolidated playbooks for complete Satellite configuration management:

1. **satellite_configuration_manager.yml** - Unified configuration operations
2. **satellite_health_monitoring.yml** - Health checks and backups  
3. **satellite_email_notifications.yml** - Email server and notifications

## Features

- **Unified Interface**: Single playbook with operation parameter
- **API-Based**: Uses Satellite REST API for reliability
- **Comprehensive Error Handling**: Retry logic, rescue blocks, detailed errors
- **Fallback Options**: Multiple methods with graceful degradation
- **AAP 2.6 Compatible**: Designed for Ansible Automation Platform 2.6
- **No Hardcoded Credentials**: Uses variables and environment variables
- **Survey Support**: Pre-configured surveys for AAP job templates

## Quick Start

### Configure Compute Profiles for PXE Boot

```bash
ansible-playbook satellite_configuration_manager.yml \
  -e operation=compute_profiles \
  -e satellite_password=password
```

### Discover Satellite Defaults

```bash
ansible-playbook satellite_configuration_manager.yml \
  -e operation=discover_defaults
```

### Fix PXE Templates

```bash
ansible-playbook satellite_configuration_manager.yml \
  -e operation=fix_pxe_templates
```

### Run Health Check

```bash
ansible-playbook satellite_health_monitoring.yml \
  -e operation=health_check \
  -e satellite_password=password
```

### Backup Configuration

```bash
ansible-playbook satellite_health_monitoring.yml \
  -e operation=backup
```

### Configure Email Server

```bash
ansible-playbook satellite_email_notifications.yml \
  -e operation=configure \
  -e smtp_host=smtp.prod.spg \
  -e smtp_account=admin@prod.spg \
  -e smtp_account_password=password
```

### Send Test Email

```bash
ansible-playbook satellite_email_notifications.yml \
  -e operation=send \
  -e smtp_to_emails=['admin@example.com']
```

## Playbook Details

### 1. satellite_configuration_manager.yml

Unified Satellite configuration operations.

**Operations:**
- `compute_profiles` - Configure compute profiles for PXE boot
- `discover_defaults` - Discover and save Satellite default values
- `fix_pxe_templates` - Fix PXE templates with inst.stage2 parameter

**Common Variables:**
```yaml
operation: compute_profiles|discover_defaults|fix_pxe_templates  # Required
satellite_user: admin                                             # Default: admin
satellite_password: password                                      # Or SATELLITE_PASSWORD env var
```

**Compute Profiles Variables:**
```yaml
compute_resource_id: 1                    # Libvirt compute resource ID
pxe_bridge: virbr1                        # Bridge for PXE network
pxe_network: internal                     # Network name
subnet_id: 1                              # Provisioning subnet ID
```

**API Settings:**
```yaml
api_retry_count: 3                        # Number of retry attempts
api_retry_delay: 5                        # Seconds between retries
api_timeout: 30                           # API request timeout
```

**Tags:**
- `compute_profiles` - Compute profile configuration
- `discover_defaults` - Default value discovery
- `fix_pxe_templates` - PXE template fixes

### 2. satellite_health_monitoring.yml

Health checks and configuration backups.

**Operations:**
- `health_check` - Comprehensive Satellite health verification
- `backup` - Backup Satellite configuration files

**Common Variables:**
```yaml
operation: health_check|backup            # Required
satellite_user: admin                     # Default: admin
satellite_password: password              # Required for health_check
```

**Health Check Variables:**
```yaml
disk_warning_threshold: 80                # Disk usage warning (%)
disk_critical_threshold: 90               # Disk usage critical (%)
api_timeout: 30                           # API request timeout
```

**Backup Variables:**
```yaml
backup_root: /root/satellite-config-backups  # Backup directory
backup_retention_days: 30                    # Keep backups for N days
```

**Tags:**
- `health_check` - Health verification
- `backup` - Configuration backup

**Health Check Components:**
- Service status (foreman, httpd, postgresql, etc.)
- API accessibility (Satellite and Katello)
- DNS resolution
- DHCP leases
- TFTP directory and boot files
- Disk space usage
- Recent errors in logs
- Repository sync status

**Backup Components:**
- DNS/named configuration
- DHCP configuration
- TFTP boot files
- PXE/Grub configuration
- Foreman/Satellite configuration
- Ansible configuration
- Command history
- System information

### 3. satellite_email_notifications.yml

Email server configuration and notifications.

**Operations:**
- `configure` - Configure Postfix mail server with SMTP relay
- `send` - Send test email notification
- `verify` - Verify email configuration

**Common Variables:**
```yaml
operation: configure|send|verify          # Required
```

**SMTP Configuration:**
```yaml
smtp_host: localhost                      # SMTP server hostname
smtp_port: 587                            # SMTP server port
smtp_account: admin@prod.spg              # SMTP account username
smtp_account_password: password           # Or SMTP_PASSWORD env var
smtp_use_tls: true                        # Enable TLS/STARTTLS
smtp_from_email: admin@prod.spg           # From email address
smtp_to_emails:                           # Recipient list
  - admin@prod.spg
```

**Gmail Fallback:**
```yaml
gmail_enabled: false                      # Enable Gmail fallback
gmail_account: user@gmail.com             # Gmail address
gmail_password: app_password              # Gmail app password
```

**Email Content:**
```yaml
email_subject: Satellite Notification     # Email subject
email_body: This is a test message        # Plain text body
email_html_body: <h1>Test</h1>            # HTML body
```

**Tags:**
- `configure` - Mail server setup
- `send` - Send email
- `verify` - Verify configuration

## Ansible Automation Platform 2.6 Integration

### Creating Job Templates

All playbooks are designed to work with AAP 2.6 job templates. Below are the recommended survey configurations for each operation.

### Survey Specifications

#### Survey 1: Satellite Configuration Manager

For job template using `satellite_configuration_manager.yml`

| Question | Variable Name | Type | Default | Required | Choices |
|----------|--------------|------|---------|----------|---------|
| Operation | operation | Multiple Choice | compute_profiles | Yes | compute_profiles, discover_defaults, fix_pxe_templates |
| Satellite Password | satellite_password | Password | | Yes | |
| Satellite Username | satellite_user | Text | admin | No | |
| Compute Resource ID | compute_resource_id | Integer | 1 | No | |
| PXE Bridge Name | pxe_bridge | Text | virbr1 | No | |
| PXE Network Name | pxe_network | Text | internal | No | |
| Subnet ID | subnet_id | Integer | 1 | No | |
| API Retry Count | api_retry_count | Integer | 3 | No | |
| API Retry Delay | api_retry_delay | Integer | 5 | No | |

**Survey JSON:**
```json
{
  "name": "Satellite Configuration Manager",
  "description": "Configure Satellite settings",
  "spec": [
    {
      "question_name": "Operation",
      "question_description": "Configuration operation to perform",
      "required": true,
      "type": "multiplechoice",
      "variable": "operation",
      "choices": ["compute_profiles", "discover_defaults", "fix_pxe_templates"],
      "default": "compute_profiles"
    },
    {
      "question_name": "Satellite Password",
      "question_description": "Password for Satellite admin user",
      "required": true,
      "type": "password",
      "variable": "satellite_password"
    },
    {
      "question_name": "Satellite Username",
      "question_description": "Satellite admin username",
      "required": false,
      "type": "text",
      "variable": "satellite_user",
      "default": "admin"
    },
    {
      "question_name": "Compute Resource ID",
      "question_description": "ID of compute resource (usually 1 for Libvirt)",
      "required": false,
      "type": "integer",
      "variable": "compute_resource_id",
      "default": 1
    },
    {
      "question_name": "PXE Bridge Name",
      "question_description": "Network bridge for PXE boot",
      "required": false,
      "type": "text",
      "variable": "pxe_bridge",
      "default": "virbr1"
    },
    {
      "question_name": "PXE Network Name",
      "question_description": "Network name for PXE boot",
      "required": false,
      "type": "text",
      "variable": "pxe_network",
      "default": "internal"
    }
  ]
}
```

#### Survey 2: Satellite Health Monitoring

For job template using `satellite_health_monitoring.yml`

| Question | Variable Name | Type | Default | Required | Choices |
|----------|--------------|------|---------|----------|---------|
| Operation | operation | Multiple Choice | health_check | Yes | health_check, backup |
| Satellite Password | satellite_password | Password | | No* | |
| Satellite Username | satellite_user | Text | admin | No | |
| Backup Root Directory | backup_root | Text | /root/satellite-config-backups | No | |
| Backup Retention Days | backup_retention_days | Integer | 30 | No | |
| Disk Warning Threshold | disk_warning_threshold | Integer | 80 | No | |
| Disk Critical Threshold | disk_critical_threshold | Integer | 90 | No | |

*Required for health_check operation only

**Survey JSON:**
```json
{
  "name": "Satellite Health Monitoring",
  "description": "Health checks and backups",
  "spec": [
    {
      "question_name": "Operation",
      "question_description": "Monitoring operation to perform",
      "required": true,
      "type": "multiplechoice",
      "variable": "operation",
      "choices": ["health_check", "backup"],
      "default": "health_check"
    },
    {
      "question_name": "Satellite Password",
      "question_description": "Password for Satellite admin user (required for health_check)",
      "required": false,
      "type": "password",
      "variable": "satellite_password"
    },
    {
      "question_name": "Satellite Username",
      "question_description": "Satellite admin username",
      "required": false,
      "type": "text",
      "variable": "satellite_user",
      "default": "admin"
    },
    {
      "question_name": "Backup Root Directory",
      "question_description": "Directory to store backups",
      "required": false,
      "type": "text",
      "variable": "backup_root",
      "default": "/root/satellite-config-backups"
    },
    {
      "question_name": "Backup Retention Days",
      "question_description": "Days to keep old backups",
      "required": false,
      "type": "integer",
      "variable": "backup_retention_days",
      "default": 30,
      "min": 1,
      "max": 365
    },
    {
      "question_name": "Disk Warning Threshold",
      "question_description": "Disk usage warning percentage",
      "required": false,
      "type": "integer",
      "variable": "disk_warning_threshold",
      "default": 80,
      "min": 50,
      "max": 100
    },
    {
      "question_name": "Disk Critical Threshold",
      "question_description": "Disk usage critical percentage",
      "required": false,
      "type": "integer",
      "variable": "disk_critical_threshold",
      "default": 90,
      "min": 50,
      "max": 100
    }
  ]
}
```

#### Survey 3: Satellite Email Notifications

For job template using `satellite_email_notifications.yml`

| Question | Variable Name | Type | Default | Required | Choices |
|----------|--------------|------|---------|----------|---------|
| Operation | operation | Multiple Choice | configure | Yes | configure, send, verify |
| SMTP Host | smtp_host | Text | localhost | No | |
| SMTP Port | smtp_port | Integer | 587 | No | |
| SMTP Account | smtp_account | Text | admin@prod.spg | No | |
| SMTP Password | smtp_account_password | Password | | No* | |
| Enable TLS | smtp_use_tls | Multiple Choice | true | No | true, false |
| From Email | smtp_from_email | Text | | No | |
| To Email Addresses | smtp_to_emails | Text | admin@prod.spg | No | |
| Email Subject | email_subject | Text | Satellite Notification | No | |
| Email Body | email_body | Textarea | Test message | No | |
| Enable Gmail Fallback | gmail_enabled | Multiple Choice | false | No | true, false |
| Gmail Account | gmail_account | Text | | No | |
| Gmail Password | gmail_password | Password | | No | |

*Required for configure and send operations

**Survey JSON:**
```json
{
  "name": "Satellite Email Notifications",
  "description": "Configure and send email notifications",
  "spec": [
    {
      "question_name": "Operation",
      "question_description": "Email operation to perform",
      "required": true,
      "type": "multiplechoice",
      "variable": "operation",
      "choices": ["configure", "send", "verify"],
      "default": "configure"
    },
    {
      "question_name": "SMTP Host",
      "question_description": "SMTP server hostname or IP",
      "required": false,
      "type": "text",
      "variable": "smtp_host",
      "default": "localhost"
    },
    {
      "question_name": "SMTP Port",
      "question_description": "SMTP server port",
      "required": false,
      "type": "integer",
      "variable": "smtp_port",
      "default": 587,
      "min": 1,
      "max": 65535
    },
    {
      "question_name": "SMTP Account",
      "question_description": "SMTP authentication username",
      "required": false,
      "type": "text",
      "variable": "smtp_account",
      "default": "admin@prod.spg"
    },
    {
      "question_name": "SMTP Password",
      "question_description": "SMTP authentication password",
      "required": false,
      "type": "password",
      "variable": "smtp_account_password"
    },
    {
      "question_name": "Enable TLS",
      "question_description": "Use TLS/STARTTLS encryption",
      "required": false,
      "type": "multiplechoice",
      "variable": "smtp_use_tls",
      "choices": ["true", "false"],
      "default": "true"
    },
    {
      "question_name": "To Email Addresses",
      "question_description": "Recipient email addresses (comma-separated)",
      "required": false,
      "type": "text",
      "variable": "smtp_to_emails",
      "default": "admin@prod.spg"
    },
    {
      "question_name": "Email Subject",
      "question_description": "Email subject line",
      "required": false,
      "type": "text",
      "variable": "email_subject",
      "default": "Satellite Notification"
    },
    {
      "question_name": "Email Body",
      "question_description": "Email message body",
      "required": false,
      "type": "textarea",
      "variable": "email_body",
      "default": "This is a test notification"
    }
  ]
}
```

### Creating Job Templates in AAP 2.6

1. Navigate to **Resources** > **Templates** > **Add** > **Add job template**

2. Fill in basic information:
   - **Name**: "Satellite Configuration Manager" (or other)
   - **Job Type**: Run
   - **Inventory**: Your Satellite inventory
   - **Project**: Your Git project with these playbooks
   - **Playbook**: Select the appropriate playbook
   - **Credentials**: Machine credential for Satellite server

3. Under **Survey**:
   - Enable **Survey**
   - Click **Add** to add survey questions
   - Use the tables above to configure each question
   - Or import the JSON survey specification

4. **Launch Options**:
   - Enable **Prompt on Launch** for extra variables if needed
   - Enable **Enable Webhook** for external triggering (optional)

5. **Save** the template

### Running Job Templates

#### Via Web UI:
1. Navigate to **Resources** > **Templates**
2. Click the launch icon next to your template
3. Fill in the survey form
4. Click **Launch**

#### Via API:
```bash
curl -X POST https://aap-controller/api/v2/job_templates/ID/launch/ \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "extra_vars": {
      "operation": "health_check",
      "satellite_password": "password"
    }
  }'
```

#### Via awx CLI:
```bash
awx job_templates launch \
  --name "Satellite Configuration Manager" \
  --extra-vars '{"operation": "compute_profiles"}'
```

## Workflow Examples

### Complete Satellite Configuration Workflow

```bash
# 1. Discover defaults
ansible-playbook satellite_configuration_manager.yml \
  -e operation=discover_defaults

# 2. Configure compute profiles
ansible-playbook satellite_configuration_manager.yml \
  -e operation=compute_profiles \
  -e satellite_password=password

# 3. Fix PXE templates
ansible-playbook satellite_configuration_manager.yml \
  -e operation=fix_pxe_templates

# 4. Configure email notifications
ansible-playbook satellite_email_notifications.yml \
  -e operation=configure \
  -e smtp_host=smtp.prod.spg \
  -e smtp_account=admin@prod.spg \
  -e smtp_account_password=password

# 5. Run health check
ansible-playbook satellite_health_monitoring.yml \
  -e operation=health_check \
  -e satellite_password=password

# 6. Create backup
ansible-playbook satellite_health_monitoring.yml \
  -e operation=backup
```

### Scheduled Maintenance Workflow

Create an AAP 2.6 workflow template:

1. **Daily Health Check** (scheduled daily)
   - Job: Satellite Health Monitoring (operation=health_check)
   - Schedule: Daily at 2:00 AM

2. **Weekly Backup** (scheduled weekly)
   - Job: Satellite Health Monitoring (operation=backup)
   - Schedule: Sunday at 1:00 AM

3. **Monthly Configuration Audit** (scheduled monthly)
   - Job: Satellite Configuration Manager (operation=discover_defaults)
   - Schedule: First day of month at 3:00 AM

## Authentication Methods

All playbooks support multiple authentication methods:

1. **Command-line variables**: `-e satellite_password=password`
2. **Environment variables**: `export SATELLITE_PASSWORD=password`
3. **AAP Credentials**: Use AAP credential types
4. **Survey prompts**: Collect via AAP survey

**Recommended for AAP 2.6:**

Create custom credential types:

```yaml
# Satellite Credential Type
INPUT:
  fields:
    - id: username
      type: string
      label: Satellite Username
      default: admin
    - id: password
      type: string
      label: Satellite Password
      secret: true
  required:
    - password

INJECTOR:
  extra_vars:
    satellite_user: "{{ username }}"
    satellite_password: "{{ password }}"
```

## Error Handling

All playbooks include comprehensive error handling:

### Retry Logic
```yaml
retries: 3
delay: 5
```

### Pre-flight Validation
- Required parameters checked before execution
- Credentials validated
- Tool availability verified

### Fallback Options
- Multiple authentication methods
- Alternative commands when primary fails
- Graceful degradation for optional features

## Troubleshooting

### Configuration Manager Issues

**Compute Profiles Not Updating:**
```bash
# Check API connectivity
curl -u admin:password -k https://satellite.prod.spg/api/status

# Verify compute resource ID
hammer compute-resource list
```

**PXE Template Fix Not Working:**
```bash
# Check template location
find / -name "kickstart_kernel_options.erb"

# Verify Foreman restarted
systemctl status foreman

# Rebuild host configs
hammer host rebuild-config --name HOST_NAME
```

### Health Monitoring Issues

**Service Status Incorrect:**
```bash
# Refresh systemd
systemctl daemon-reload

# Check specific service
systemctl status foreman -l
```

**Disk Space Warnings:**
```bash
# Check detailed usage
du -sh /var/lib/pulp/*

# Clean old content
foreman-maintain content clean-orphaned-objects
```

### Email Notification Issues

**Email Not Sending:**
```bash
# Check Postfix logs
tail -f /var/log/maillog

# Test SMTP connectivity
telnet smtp.prod.spg 587

# Verify SASL authentication
postconf smtp_sasl_auth_enable
```

**Gmail Fallback Failing:**
- Ensure using Gmail App Password (not regular password)
- Check "Less secure app access" settings
- Verify 2FA is enabled for app passwords

## Migration from Old Playbooks

Old playbooks consolidated into new structure:

| Old Playbook | New Playbook | Operation |
|--------------|--------------|-----------|
| configure_compute_profiles.yml | satellite_configuration_manager.yml | compute_profiles |
| discover_satellite_defaults.yml | satellite_configuration_manager.yml | discover_defaults |
| fix_pxe_templates.yml | satellite_configuration_manager.yml | fix_pxe_templates |
| fix_pxe_templates_filesystem.yml | satellite_configuration_manager.yml | fix_pxe_templates |
| satellite_health_check.yml | satellite_health_monitoring.yml | health_check |
| satellite_config_backup.yml | satellite_health_monitoring.yml | backup |
| emailserveronsatellite.yml | satellite_email_notifications.yml | configure/send |
| create_node.yml | (Moved to node_provisioning) | N/A |

### Variable Name Changes

| Old Variable | New Variable | Notes |
|--------------|--------------|-------|
| None | operation | New: operation selector |
| None | api_retry_count | New: retry configuration |
| None | api_retry_delay | New: retry delay |
| satellite_password | satellite_password | Same but now supports env var |
| smtp_account_password | smtp_account_password | Same but now supports env var |

## Performance Tips

### API Operations
- Increase `api_retry_count` for slow networks
- Adjust `api_timeout` for busy systems
- Use `api_retry_delay` to avoid overwhelming API

### Backup Operations
- Exclude large directories if space limited
- Use `backup_retention_days` to manage disk usage
- Run backups during low-activity periods

### Email Operations
- Use Gmail fallback for reliability
- Test configuration before production use
- Monitor mail queue for stuck messages

## Security Considerations

### Credential Management
- Never hardcode passwords in playbooks
- Use AAP credential types
- Rotate passwords regularly

### File Permissions
- SASL password files: 0600
- Backup archives: 0700
- Configuration files: Follow system defaults

### Network Security
- Use TLS for SMTP when possible
- Validate certificates in production
- Restrict API access to trusted networks

## Support

For issues or questions:
1. Check troubleshooting sections above
2. Review Satellite logs: `/var/log/foreman/production.log`
3. Use verbose mode: `ansible-playbook -vvv`
4. Check AAP job output for detailed errors

## Related Documentation

- [Red Hat Satellite Documentation](https://access.redhat.com/documentation/en-us/red_hat_satellite/)
- [Ansible Automation Platform 2.6 Documentation](https://access.redhat.com/documentation/en-us/red_hat_ansible_automation_platform/2.6)
- [Node Provisioning Playbooks](../node_provisioning/README.md)
- [Ansible Configuration Playbooks](../ansible_configuration/README.md)

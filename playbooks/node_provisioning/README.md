# Node Provisioning Playbooks

Comprehensive Red Hat Satellite node management and PXE boot provisioning automation.

## Overview

This directory contains three consolidated playbooks for complete node lifecycle management:

1. **satellite_node_manager.yml** - Unified CRUD operations (create, bulk create, delete, list)
2. **satellite_node_post_install.yml** - Post-installation configuration and registration
3. **pxe_boot_troubleshoot.yml** - PXE boot diagnostics and automatic remediation

## Features

- **Unified Interface**: Single playbook for multiple operations using operation parameter
- **API-Based**: Uses Satellite REST API instead of shell commands for reliability
- **Comprehensive Error Handling**: Retry logic, rescue blocks, detailed error messages
- **Fallback Options**: Multiple authentication methods, optional services, graceful degradation
- **Conditional Execution**: Tags support for partial runs, when clauses for smart decisions
- **No Hardcoded Credentials**: Uses variables and environment variables
- **Detailed Troubleshooting**: Helpful error messages with resolution steps

## Quick Start

### Create a Single Node

```bash
ansible-playbook satellite_node_manager.yml \
  -e operation=create \
  -e node_name=node010 \
  -e node_mac=52:54:00:00:00:0a \
  -e satellite_user=admin \
  -e satellite_password=password
```

### Create Multiple Nodes

```bash
ansible-playbook satellite_node_manager.yml \
  -e operation=bulk \
  -e start_slot=11 \
  -e node_count=5 \
  -e satellite_user=admin \
  -e satellite_password=password
```

### Configure Newly Installed Node

```bash
ansible-playbook satellite_node_post_install.yml \
  -i node015.prod.spg, \
  -e admin_user=admin \
  -e admin_password=SecurePass123 \
  -e satellite_activation_key=rhel8-compute
```

### Troubleshoot PXE Boot

```bash
ansible-playbook pxe_boot_troubleshoot.yml \
  -e host_name=node020.prod.spg \
  -e vm_name=node020 \
  -e satellite_password=password
```

## Playbook Details

### 1. satellite_node_manager.yml

Unified node management for all CRUD operations.

**Operations:**
- `create` - Create single node
- `bulk` - Create multiple nodes in sequence
- `delete` - Delete node from Satellite
- `list` - List all nodes or search by pattern

**Required Variables:**

Common:
```yaml
operation: create|bulk|delete|list
satellite_user: admin                    # Default: admin
satellite_password: password             # Or set SATELLITE_PASSWORD env var
```

For `create` operation:
```yaml
node_name: node010                       # Node identifier (no domain)
node_mac: 52:54:00:00:00:0a             # MAC address for NIC
```

For `bulk` operation:
```yaml
start_slot: 10                           # Starting node number
node_count: 5                            # Number of nodes to create
```

For `delete` operation:
```yaml
node_name: node010                       # Node to delete
confirm_delete: true                     # Required safety confirmation
```

For `list` operation:
```yaml
search_pattern: node*                    # Optional search filter
```

**Optional Variables:**
```yaml
organization: Default Organization
location: Default Location
hostgroup: Compute
compute_resource: kaso.prod.spg
compute_profile: 1-Small
domain: prod.spg
subnet: Internal
network_bridge: virbr1
disk_size_gb: 50
memory_mb: 2048
cpu_count: 2

api_retry_count: 3                       # Number of retry attempts
api_retry_delay: 5                       # Seconds between retries
```

**Tags:**
- `validate` - Pre-flight checks only
- `create` - Node creation tasks
- `bulk` - Bulk operation tasks
- `delete` - Node deletion tasks
- `list` - Node listing tasks

**Examples:**

Create with custom specifications:
```bash
ansible-playbook satellite_node_manager.yml \
  -e operation=create \
  -e node_name=node100 \
  -e node_mac=52:54:00:00:00:64 \
  -e memory_mb=4096 \
  -e cpu_count=4 \
  -e disk_size_gb=100 \
  -e hostgroup=Database
```

Create bulk nodes with auto-generated MACs:
```bash
ansible-playbook satellite_node_manager.yml \
  -e operation=bulk \
  -e start_slot=200 \
  -e node_count=10 \
  -e compute_profile=2-Medium
```

List nodes matching pattern:
```bash
ansible-playbook satellite_node_manager.yml \
  -e operation=list \
  -e search_pattern="node1*"
```

Delete node with confirmation:
```bash
ansible-playbook satellite_node_manager.yml \
  -e operation=delete \
  -e node_name=node010 \
  -e confirm_delete=true
```

### 2. satellite_node_post_install.yml

Post-installation configuration after OS deployment.

**Features:**
- Admin user creation with SSH key generation
- SSH configuration (root login, host key checking)
- Hostname configuration
- Satellite registration with activation keys
- Firewall configuration (required + optional services)
- Optional system updates

**Required Variables:**
```yaml
admin_user: admin                        # Admin username to create
admin_password: SecurePass123            # Admin user password
satellite_activation_key: rhel8-compute  # Satellite activation key
```

**Optional Variables:**
```yaml
admin_groups: wheel                      # Additional groups for admin user
admin_shell: /bin/bash                   # Default shell
admin_ssh_key_type: ed25519              # SSH key type (rsa, ed25519)
admin_ssh_key_bits: 4096                 # Key size for RSA

satellite_url: https://satellite.prod.spg
satellite_org: Default_Organization

# SSH Configuration
enable_root_ssh: true                    # Allow root SSH login
disable_ssh_host_checking: true          # Disable strict host checking

# Firewall services
firewall_required_services:              # Always enabled
  - ssh
  - http
  - https

firewall_optional_services:              # Enabled if available
  - rhc
  - insights-client

# System updates
run_system_update: false                 # Full system update after config
```

**Tags:**
- `admin` - Admin user configuration
- `ssh` - SSH configuration
- `hostname` - Hostname setup
- `satellite` - Satellite registration
- `firewall` - Firewall configuration
- `update` - System updates

**Examples:**

Basic configuration:
```bash
ansible-playbook satellite_node_post_install.yml \
  -i node050.prod.spg, \
  -e admin_user=admin \
  -e admin_password=MySecurePass \
  -e satellite_activation_key=rhel8-compute
```

Configuration with system update:
```bash
ansible-playbook satellite_node_post_install.yml \
  -i node051.prod.spg, \
  -e admin_user=sysadmin \
  -e admin_password=SecurePass123 \
  -e satellite_activation_key=rhel8-database \
  -e run_system_update=true
```

Only register to Satellite:
```bash
ansible-playbook satellite_node_post_install.yml \
  -i node052.prod.spg, \
  --tags satellite \
  -e satellite_activation_key=rhel8-compute
```

Skip firewall configuration:
```bash
ansible-playbook satellite_node_post_install.yml \
  -i node053.prod.spg, \
  --skip-tags firewall \
  -e admin_user=admin \
  -e admin_password=Pass123 \
  -e satellite_activation_key=rhel8-compute
```

### 3. pxe_boot_troubleshoot.yml

Comprehensive PXE boot diagnostics and automatic remediation.

**Features:**
- VM discovery from KVM hypervisor (MAC, firmware type)
- Automatic PXE loader configuration (BIOS vs UEFI)
- Build mode enablement
- PXE configuration file verification
- Boot file existence checks
- inst.stage2 parameter validation
- Repository URL reachability tests
- Comprehensive troubleshooting guidance

**Required Variables:**
```yaml
host_name: node010.prod.spg              # Satellite host FQDN
vm_name: node010                         # VM name in KVM
satellite_password: password             # Or set SATELLITE_PASSWORD env var
```

**Optional Variables:**
```yaml
satellite_user: admin                    # Default: admin
kvm_uri: qemu:///system                  # KVM connection URI
api_retry_count: 3                       # API retry attempts
api_retry_delay: 5                       # Seconds between retries
```

**Requirements:**
- `kvm` group in inventory with KVM hypervisor host
- `satellite` group in inventory with Satellite server
- VM must exist in KVM
- Host must exist in Satellite

**Example Inventory:**
```ini
[kvm]
kaso.prod.spg

[satellite]
satellite.prod.spg
```

**Examples:**

Basic troubleshooting:
```bash
ansible-playbook pxe_boot_troubleshoot.yml \
  -e host_name=node010.prod.spg \
  -e vm_name=node010 \
  -e satellite_password=password
```

With custom KVM URI:
```bash
ansible-playbook pxe_boot_troubleshoot.yml \
  -e host_name=node011.prod.spg \
  -e vm_name=node011 \
  -e kvm_uri=qemu+ssh://root@kaso.prod.spg/system \
  -e satellite_password=password
```

Using environment variable for password:
```bash
export SATELLITE_PASSWORD=password
ansible-playbook pxe_boot_troubleshoot.yml \
  -e host_name=node012.prod.spg \
  -e vm_name=node012
```

## Authentication Methods

All playbooks support multiple authentication methods (tried in order):

1. **Command-line variables**: `-e satellite_user=admin -e satellite_password=password`
2. **Environment variables**: `export SATELLITE_PASSWORD=password`
3. **Interactive prompt**: Playbook will prompt if not provided

**Recommended Approach:**

For automation:
```bash
export SATELLITE_PASSWORD=your_password
ansible-playbook satellite_node_manager.yml -e operation=bulk -e start_slot=10 -e node_count=5
```

For one-off tasks:
```bash
ansible-playbook satellite_node_manager.yml -e operation=create -e node_name=node010 -e node_mac=52:54:00:00:00:0a
# Will prompt for password interactively
```

## Error Handling

All playbooks include comprehensive error handling:

### Retry Logic
Failed API calls automatically retry with configurable attempts:
```yaml
api_retry_count: 3
api_retry_delay: 5
```

### Rescue Blocks
Operations that may fail have rescue blocks with troubleshooting:
```yaml
- name: Risky operation
  block:
    - name: Try operation
      ...
  rescue:
    - name: Handle failure
      ansible.builtin.debug:
        msg: |
          Operation failed
          
          Troubleshooting:
          1. Check ...
          2. Verify ...
```

### Pre-flight Validation
All playbooks validate requirements before execution:
- Required parameters present
- API connectivity
- Tools availability (hammer, virsh)
- Credentials validity

### Fallback Options
When primary method fails, playbooks try alternatives:
- Multiple authentication methods
- Optional services (continues without)
- Alternative commands (API vs CLI)

## Satellite Template Association and Parameters

After generating the RHEL 9.7 post-kickstart template, complete these steps to make it active for RHEL 9.7 and to provide required parameters consumed by the %post script.

### 1) Push/Update the Provisioning Template (API)

This ensures the template exists on Satellite and associates it with the RHEL 9 family.

```bash
export SATELLITE_PASSWORD='your_password'
ansible-playbook push_provisioning_template.yml -e satellite_username=admin
```

### 2) Set as Default 'provision' for RHEL 9.7 (API)

This explicitly maps the template as the default provision template for RHEL 9.7 (fallbacks to RHEL 9 if 9.7 not present).

```bash
export SATELLITE_PASSWORD='your_password'
ansible-playbook associate_template_to_os.yml \
  -e satellite_username=admin -e os_major=9 -e os_minor=7 \
  -e template_name="RHEL 9.7 x86_64 Post-Kickstart Default"
```

### 3) Create Global Parameters Consumed by %post (API)

Sets required Foreman parameters: admin_user, admin_password, activation_keys, ks_enable_updates.

```bash
export SATELLITE_PASSWORD='your_password'
ansible-playbook set_foreman_parameters.yml \
  -e satellite_username=admin \
  -e admin_user=admin \
  -e admin_password='ChangeMe!' \
  -e activation_keys='9:RHEL9-AK' \
  -e ks_enable_updates=true
```

### Hammer Alternative (Run on Satellite)

If you prefer hammer, use the helper script:

```bash
cd ../../scripts
chmod +x hammer_associate_and_params.sh
./hammer_associate_and_params.sh \
  --template "RHEL 9.7 x86_64 Post-Kickstart Default" \
  --os-major 9 --os-minor 7 \
  --admin-user admin --admin-pass 'ChangeMe!' \
  --activation-keys '9:RHEL9-AK' \
  --enable-updates true
```

### 4) Verify Post-Install Result on a Fresh Host

After provisioning a new host with the OS set to RHEL 9.7 (and using the default provision template), verify the %post ran by checking for the summary file:

```bash
ansible-playbook verify_post_install_summary.yml \
  -e target_host=newly.provisioned.host.example.com \
  -e ssh_user=root \
  -e ansible_ssh_private_key_file=~/.ssh/id_rsa
```

Expected: The file `/root/post-install-summary.txt` exists and contains a brief summary of the configuration performed during %post.


## Common Variables

Create a variables file for consistent configuration:

**vars.yml**:
```yaml
# Satellite Configuration
satellite_user: admin
satellite_password: "{{ lookup('env', 'SATELLITE_PASSWORD') }}"
organization: Default Organization
location: Default Location

# Node Defaults
hostgroup: Compute
compute_resource: kaso.prod.spg
compute_profile: 1-Small
domain: prod.spg
subnet: Internal
network_bridge: virbr1

# VM Specifications
disk_size_gb: 50
memory_mb: 2048
cpu_count: 2

# Post-Install Configuration
admin_user: admin
admin_password: "{{ lookup('env', 'ADMIN_PASSWORD') }}"
satellite_activation_key: rhel8-compute
satellite_url: https://satellite.prod.spg
satellite_org: Default_Organization

# API Settings
api_retry_count: 3
api_retry_delay: 5
```

Use with:
```bash
export SATELLITE_PASSWORD=your_sat_password
export ADMIN_PASSWORD=your_admin_password

ansible-playbook satellite_node_manager.yml \
  -e @vars.yml \
  -e operation=create \
  -e node_name=node010 \
  -e node_mac=52:54:00:00:00:0a
```

## Workflow Examples

### Complete Node Provisioning Workflow

1. **Create node in Satellite**:
```bash
ansible-playbook satellite_node_manager.yml \
  -e operation=create \
  -e node_name=node100 \
  -e node_mac=52:54:00:00:00:64 \
  -e satellite_password=password
```

2. **Troubleshoot if PXE boot fails**:
```bash
ansible-playbook pxe_boot_troubleshoot.yml \
  -e host_name=node100.prod.spg \
  -e vm_name=node100 \
  -e satellite_password=password
```

3. **Configure after OS installation**:
```bash
# Wait for OS to install, then:
ansible-playbook satellite_node_post_install.yml \
  -i node100.prod.spg, \
  -e admin_user=admin \
  -e admin_password=SecurePass123 \
  -e satellite_activation_key=rhel8-compute
```

### Bulk Node Deployment

1. **Create 10 nodes**:
```bash
ansible-playbook satellite_node_manager.yml \
  -e operation=bulk \
  -e start_slot=200 \
  -e node_count=10 \
  -e compute_profile=2-Medium \
  -e satellite_password=password
```

2. **Verify creation**:
```bash
ansible-playbook satellite_node_manager.yml \
  -e operation=list \
  -e search_pattern="node2*"
```

3. **Monitor boot process**:
```bash
# On KVM host
for i in {200..209}; do
  echo "=== node${i} ==="
  virsh domstate node${i}
done
```

4. **Configure all nodes after installation**:
```bash
# Create inventory file
cat > nodes.ini << EOF
[new_nodes]
node200.prod.spg
node201.prod.spg
...
node209.prod.spg
EOF

# Run post-install
ansible-playbook satellite_node_post_install.yml \
  -i nodes.ini \
  -e admin_user=admin \
  -e admin_password=SecurePass123 \
  -e satellite_activation_key=rhel8-compute
```

## Troubleshooting

### Node Creation Fails

**Issue**: API call returns 422 (Unprocessable Entity)

**Solutions**:
1. Check if MAC address already exists: `hammer host list --search "mac=52:54:00:00:00:0a"`
2. Verify hostgroup exists: `hammer hostgroup list`
3. Check compute resource: `hammer compute-resource list`
4. Validate network/subnet: `hammer subnet list`

**Issue**: Node created but not visible in compute resource

**Solutions**:
1. Check compute resource connection: `hammer compute-resource info --name kaso.prod.spg`
2. Verify libvirt daemon running: `systemctl status libvirtd`
3. Test connection: `virsh -c qemu:///system list --all`

### PXE Boot Issues

**Issue**: VM boots but no PXE config found

**Solutions**:
1. Run troubleshooting playbook: `ansible-playbook pxe_boot_troubleshoot.yml ...`
2. Check TFTP service: `systemctl status tftp.socket`
3. Verify firewall: `firewall-cmd --list-services | grep tftp`
4. Regenerate config: `hammer host rebuild-config --name node010.prod.spg`

**Issue**: inst.stage2 URL not reachable

**Solutions**:
1. Check repository sync: `hammer repository list --organization "Default Organization"`
2. Sync repository: `hammer repository synchronize --name "Red Hat Enterprise Linux 8 for x86_64 - BaseOS RPMs x86_64 8"`
3. Verify medium path: `hammer medium list`
4. Test URL manually: `curl -I http://satellite.prod.spg/pulp/content/...`

### Post-Install Issues

**Issue**: Cannot connect to newly installed node

**Solutions**:
1. Verify node completed installation: Check KVM console
2. Check SSH service: `systemctl status sshd` (from console)
3. Test network: `ping node010.prod.spg`
4. Verify DNS: `nslookup node010.prod.spg`

**Issue**: Satellite registration fails

**Solutions**:
1. Check activation key: `hammer activation-key list`
2. Verify CA cert: `curl -k https://satellite.prod.spg/pub/katello-ca-consumer-latest.noarch.rpm`
3. Test from node: `subscription-manager register --org "Default_Organization" --activationkey rhel8-compute`
4. Check Satellite logs: `tail -f /var/log/foreman/production.log`

## Performance Tips

### Bulk Operations
For creating many nodes, use bulk operation instead of loops:
```bash
# Good
ansible-playbook satellite_node_manager.yml -e operation=bulk -e start_slot=100 -e node_count=50

# Avoid
for i in {100..149}; do
  ansible-playbook satellite_node_manager.yml -e operation=create -e node_name=node${i} ...
done
```

### Parallel Execution
Use Ansible forks for parallel post-install:
```bash
ansible-playbook satellite_node_post_install.yml -i nodes.ini -f 10
```

### API Retry Settings
Adjust retry settings for slow networks:
```yaml
api_retry_count: 5
api_retry_delay: 10
```

## Security Considerations

### Credential Management
Never hardcode passwords in playbooks or version control:

**Bad**:
```yaml
satellite_password: admin123
```

**Good**:
```yaml
satellite_password: "{{ lookup('env', 'SATELLITE_PASSWORD') }}"
```

### SSH Keys
Generate unique SSH keys per admin user:
```yaml
admin_ssh_key_type: ed25519
```

### Firewall
Always enable required firewall services:
```yaml
firewall_required_services:
  - ssh
  - http
  - https
```

### Root Access
Consider disabling root SSH after setup:
```yaml
enable_root_ssh: false
```

## Migration from Old Playbooks

See [MIGRATION.md](MIGRATION.md) for detailed migration guide from previous playbooks.

## Support

For issues or questions:
1. Check troubleshooting sections above
2. Review Satellite logs: `/var/log/foreman/production.log`
3. Check Ansible verbose output: `ansible-playbook -vvv ...`
4. Verify API connectivity: `curl -u admin:password -k https://satellite.prod.spg/api/status`

## Related Documentation

- [Red Hat Satellite API Documentation](https://access.redhat.com/documentation/en-us/red_hat_satellite/)
- [Ansible URI Module](https://docs.ansible.com/ansible/latest/collections/ansible/builtin/uri_module.html)
- [Libvirt API Documentation](https://libvirt.org/html/index.html)

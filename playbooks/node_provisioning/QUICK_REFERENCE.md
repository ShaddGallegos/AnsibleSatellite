# Node Provisioning Quick Reference

Fast command reference for common node provisioning tasks.

## Prerequisites

```bash
# Set credentials once
export SATELLITE_PASSWORD=your_password
export ADMIN_PASSWORD=your_admin_password

# Verify connectivity
curl -u admin:$SATELLITE_PASSWORD -k https://satellite.prod.spg/api/status
```

## Common Commands

### Create Single Node

```bash
ansible-playbook satellite_node_manager.yml \
  -e operation=create \
  -e node_name=node010 \
  -e node_mac=52:54:00:00:00:0a
```

### Create Multiple Nodes

```bash
ansible-playbook satellite_node_manager.yml \
  -e operation=bulk \
  -e start_slot=10 \
  -e node_count=5
```

### List All Nodes

```bash
ansible-playbook satellite_node_manager.yml \
  -e operation=list
```

### Search Nodes

```bash
ansible-playbook satellite_node_manager.yml \
  -e operation=list \
  -e search_pattern="node1*"
```

### Delete Node

```bash
ansible-playbook satellite_node_manager.yml \
  -e operation=delete \
  -e node_name=node010 \
  -e confirm_delete=true
```

### Configure Node After Install

```bash
ansible-playbook satellite_node_post_install.yml \
  -i node010.prod.spg, \
  -e admin_user=admin \
  -e admin_password=$ADMIN_PASSWORD \
  -e satellite_activation_key=rhel8-compute
```

### Troubleshoot PXE Boot

```bash
ansible-playbook pxe_boot_troubleshoot.yml \
  -e host_name=node010.prod.spg \
  -e vm_name=node010
```

## Complete Workflows

### Single Node Deployment

```bash
# 1. Create
ansible-playbook satellite_node_manager.yml \
  -e operation=create \
  -e node_name=node050 \
  -e node_mac=52:54:00:00:00:32

# 2. Boot VM (on KVM host)
ssh kaso.prod.spg "virsh start node050"

# 3. Monitor installation (optional)
ssh kaso.prod.spg "virsh console node050"

# 4. Wait for installation to complete (check via console or Satellite web UI)

# 5. Configure
ansible-playbook satellite_node_post_install.yml \
  -i node050.prod.spg, \
  -e admin_user=admin \
  -e admin_password=$ADMIN_PASSWORD \
  -e satellite_activation_key=rhel8-compute
```

### Bulk Node Deployment

```bash
# 1. Create 10 nodes
ansible-playbook satellite_node_manager.yml \
  -e operation=bulk \
  -e start_slot=100 \
  -e node_count=10

# 2. Boot all VMs (on KVM host)
ssh kaso.prod.spg 'for i in {100..109}; do virsh start node$(printf %03d $i); done'

# 3. Wait for installations to complete

# 4. Configure all nodes in parallel
cat > /tmp/nodes.ini << EOF
[new_nodes]
$(for i in {100..109}; do echo "node$(printf %03d $i).prod.spg"; done)
EOF

ansible-playbook satellite_node_post_install.yml \
  -i /tmp/nodes.ini \
  -e admin_user=admin \
  -e admin_password=$ADMIN_PASSWORD \
  -e satellite_activation_key=rhel8-compute \
  -f 5
```

### Lab Environment (First 5 Nodes)

```bash
# Quick lab setup
ansible-playbook satellite_node_manager.yml \
  -e operation=bulk \
  -e start_slot=1 \
  -e node_count=5 \
  -e hostgroup=Compute

# Boot them
ssh kaso.prod.spg 'for i in {1..5}; do virsh start node$(printf %03d $i); done'

# Configure after install
ansible-playbook satellite_node_post_install.yml \
  -i node001.prod.spg,node002.prod.spg,node003.prod.spg,node004.prod.spg,node005.prod.spg \
  -e admin_user=admin \
  -e admin_password=$ADMIN_PASSWORD \
  -e satellite_activation_key=rhel8-compute
```

## Advanced Usage

### Custom Node Specifications

```bash
ansible-playbook satellite_node_manager.yml \
  -e operation=create \
  -e node_name=dbserver01 \
  -e node_mac=52:54:00:00:10:01 \
  -e hostgroup=Database \
  -e compute_profile=3-Large \
  -e memory_mb=8192 \
  -e cpu_count=4 \
  -e disk_size_gb=200
```

### Partial Configuration (Tags)

```bash
# Only configure SSH
ansible-playbook satellite_node_post_install.yml \
  -i node010.prod.spg, \
  --tags ssh

# Skip system updates
ansible-playbook satellite_node_post_install.yml \
  -i node011.prod.spg, \
  --skip-tags update \
  -e admin_user=admin \
  -e admin_password=$ADMIN_PASSWORD \
  -e satellite_activation_key=rhel8-compute

# Only register to Satellite
ansible-playbook satellite_node_post_install.yml \
  -i node012.prod.spg, \
  --tags satellite \
  -e satellite_activation_key=rhel8-compute
```

### Pre-flight Validation Only

```bash
ansible-playbook satellite_node_manager.yml \
  --tags validate \
  -e operation=create \
  -e node_name=node999 \
  -e node_mac=52:54:00:00:03:e7
```

## Troubleshooting Commands

### Check Node Status

```bash
# Via Satellite API
curl -u admin:$SATELLITE_PASSWORD -k \
  "https://satellite.prod.spg/api/hosts?search=name=node010.prod.spg"

# Via hammer CLI (on Satellite)
ssh satellite.prod.spg "hammer host info --name node010.prod.spg"
```

### Check VM Status

```bash
# On KVM host
ssh kaso.prod.spg "virsh domstate node010"
ssh kaso.prod.spg "virsh dominfo node010"
ssh kaso.prod.spg "virsh domiflist node010"
```

### Check PXE Configuration

```bash
# On Satellite
ssh satellite.prod.spg "ls -lh /var/lib/tftpboot/pxelinux.cfg/"
ssh satellite.prod.spg "ls -lh /var/lib/tftpboot/grub2/"

# Check specific node config
ssh satellite.prod.spg "cat /var/lib/tftpboot/pxelinux.cfg/01-52-54-00-00-00-0a"
```

### Monitor Logs

```bash
# Satellite logs
ssh satellite.prod.spg "tail -f /var/log/foreman/production.log"

# TFTP requests
ssh satellite.prod.spg "tail -f /var/log/messages | grep tftp"

# VM console
ssh kaso.prod.spg "virsh console node010"
```

### Force PXE Config Regeneration

```bash
# On Satellite
ssh satellite.prod.spg "hammer host rebuild-config --name node010.prod.spg"
```

### Test Network Connectivity

```bash
# From node to Satellite
ssh node010.prod.spg "ping -c 3 satellite.prod.spg"
ssh node010.prod.spg "curl -k https://satellite.prod.spg"

# From Satellite to node
ssh satellite.prod.spg "ping -c 3 node010.prod.spg"
ssh satellite.prod.spg "ssh -o StrictHostKeyChecking=no root@node010.prod.spg hostname"
```

## Common Variables

### Node Manager Variables

```yaml
# Required
operation: create|bulk|delete|list
satellite_user: admin
satellite_password: password

# Node specs
node_name: node010
node_mac: 52:54:00:00:00:0a
start_slot: 10
node_count: 5

# Customization
hostgroup: Compute
compute_resource: kaso.prod.spg
compute_profile: 1-Small
memory_mb: 2048
cpu_count: 2
disk_size_gb: 50

# API settings
api_retry_count: 3
api_retry_delay: 5
```

### Post-Install Variables

```yaml
# Required
admin_user: admin
admin_password: SecurePass123
satellite_activation_key: rhel8-compute

# Optional
satellite_url: https://satellite.prod.spg
satellite_org: Default_Organization
enable_root_ssh: true
disable_ssh_host_checking: true
run_system_update: false

# Firewall services
firewall_required_services:
  - ssh
  - http
  - https
firewall_optional_services:
  - rhc
  - insights-client
```

### PXE Troubleshoot Variables

```yaml
# Required
host_name: node010.prod.spg
vm_name: node010
satellite_password: password

# Optional
satellite_user: admin
kvm_uri: qemu:///system
api_retry_count: 3
api_retry_delay: 5
```

## Quick Reference: File Locations

### On Satellite Server

```
/var/lib/tftpboot/pxelinux.cfg/     # BIOS PXE configs
/var/lib/tftpboot/grub2/            # UEFI PXE configs
/var/lib/tftpboot/boot/             # Kernel and initrd files
/var/log/foreman/production.log     # Satellite main log
/var/log/messages                   # TFTP requests
```

### On KVM Host

```
/etc/libvirt/qemu/                  # VM definitions
/var/lib/libvirt/images/            # VM disk images
```

## Useful One-Liners

### Generate MAC Address

```bash
# For node number 10
printf "52:54:00:00:00:%02x\n" 10
```

### Count Active VMs

```bash
ssh kaso.prod.spg "virsh list --state-running | wc -l"
```

### List All Nodes in Satellite

```bash
ssh satellite.prod.spg "hammer host list --search 'name ~ node' --fields id,name,ip,mac"
```

### Check Subscription Status

```bash
ssh node010.prod.spg "subscription-manager status"
```

### Bulk VM Operations

```bash
# Start all node VMs
ssh kaso.prod.spg 'for vm in $(virsh list --all --name | grep "^node"); do virsh start $vm; done'

# Stop all node VMs
ssh kaso.prod.spg 'for vm in $(virsh list --name | grep "^node"); do virsh shutdown $vm; done'

# Force off all node VMs
ssh kaso.prod.spg 'for vm in $(virsh list --name | grep "^node"); do virsh destroy $vm; done'
```

### Bulk Node Deletion

```bash
# Delete nodes 100-109
for i in {100..109}; do
  ansible-playbook satellite_node_manager.yml \
    -e operation=delete \
    -e node_name=node$(printf %03d $i) \
    -e confirm_delete=true
done
```

## Environment Setup Script

Save as `setup-env.sh`:

```bash
#!/bin/bash
# Source this file: source setup-env.sh

export SATELLITE_PASSWORD="your_satellite_password"
export ADMIN_PASSWORD="your_admin_password"

export SAT_USER="admin"
export SAT_HOST="satellite.prod.spg"
export KVM_HOST="kaso.prod.spg"

# Shortcuts
alias sat-create='ansible-playbook satellite_node_manager.yml -e operation=create'
alias sat-bulk='ansible-playbook satellite_node_manager.yml -e operation=bulk'
alias sat-delete='ansible-playbook satellite_node_manager.yml -e operation=delete'
alias sat-list='ansible-playbook satellite_node_manager.yml -e operation=list'
alias sat-config='ansible-playbook satellite_node_post_install.yml'
alias sat-troubleshoot='ansible-playbook pxe_boot_troubleshoot.yml'

echo "Environment configured. Use sat-* aliases for quick commands."
```

Usage:
```bash
source setup-env.sh

# Now use shortcuts
sat-create -e node_name=node010 -e node_mac=52:54:00:00:00:0a
sat-list -e search_pattern="node*"
```

## Performance Tips

### Parallel Execution

```bash
# Configure 10 nodes in parallel (5 at a time)
ansible-playbook satellite_node_post_install.yml \
  -i nodes.ini \
  -e admin_user=admin \
  -e admin_password=$ADMIN_PASSWORD \
  -e satellite_activation_key=rhel8-compute \
  -f 5
```

### Increase API Retries for Slow Networks

```bash
ansible-playbook satellite_node_manager.yml \
  -e operation=bulk \
  -e start_slot=100 \
  -e node_count=20 \
  -e api_retry_count=5 \
  -e api_retry_delay=10
```

### Skip Time-Consuming Tasks

```bash
# Skip system update to save time
ansible-playbook satellite_node_post_install.yml \
  -i nodes.ini \
  --skip-tags update \
  -e admin_user=admin \
  -e admin_password=$ADMIN_PASSWORD \
  -e satellite_activation_key=rhel8-compute
```

## Help and Documentation

- Full documentation: `less README.md`
- Migration guide: `less MIGRATION.md`
- This reference: `less QUICK_REFERENCE.md`
- Ansible verbose: Add `-vvv` to any command
- Tag help: `ansible-playbook <playbook> --list-tags`

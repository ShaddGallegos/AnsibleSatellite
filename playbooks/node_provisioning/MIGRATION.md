# Migration Guide: Node Provisioning Playbooks v1.0 to v2.0

This guide helps you migrate from the old collection of 10 playbooks to the new consolidated 3-playbook structure.

## Overview

**Old Structure (v1.0)**: 10 separate playbooks with duplicated code
**New Structure (v2.0)**: 3 consolidated playbooks with unified operations

## What Changed

### Consolidated Playbooks

Old playbooks consolidated into new structure:

| Old Playbook | New Playbook | Operation |
|---|---|---|
| create_pxe_node.yml | satellite_node_manager.yml | operation=create |
| bulk_create_pxe_nodes.yml | satellite_node_manager.yml | operation=bulk |
| delete_pxe_node.yml | satellite_node_manager.yml | operation=delete |
| list_pxe_nodes.yml | satellite_node_manager.yml | operation=list |
| first5.yml | satellite_node_manager.yml | operation=bulk start_slot=1 node_count=5 |
| build_nodes_in_batches.yml | satellite_node_manager.yml | operation=bulk |
| create_batch.yml | (Integrated into satellite_node_manager.yml) |
| create_node.yml | (Integrated into satellite_node_manager.yml) |
| provision_node.yml | satellite_node_post_install.yml | - |
| pxe_boot_remediate.yml | pxe_boot_troubleshoot.yml | - |

### Major Improvements

**API-Based Operations**:
- Old: Used shell commands, curl, and hammer CLI inconsistently
- New: Unified REST API calls with proper authentication

**Error Handling**:
- Old: Minimal error checking, scripts would fail silently
- New: Comprehensive error handling with rescue blocks, retry logic, troubleshooting hints

**Credential Management**:
- Old: Hardcoded credentials (admin:r3dh4t7!)
- New: Variable-based with environment variable fallback, no hardcoded secrets

**Code Duplication**:
- Old: Same API patterns repeated across multiple files
- New: Single implementation with operation parameter

**Retry Logic**:
- Old: No retries on API failures
- New: Configurable retry count (default 3) with delay (default 5 seconds)

**Conditional Execution**:
- Old: All-or-nothing execution
- New: Tags support for partial runs, when clauses for conditional tasks

## Migration Examples

### Example 1: Creating a Single Node

**Old Command**:
```bash
ansible-playbook create_pxe_node.yml \
  --extra-vars "node_name=node010 mac_address=52:54:00:00:00:0a"
```

**New Command**:
```bash
ansible-playbook satellite_node_manager.yml \
  -e operation=create \
  -e node_name=node010 \
  -e node_mac=52:54:00:00:00:0a \
  -e satellite_password=password
```

**Changes**:
- Added `operation=create` parameter
- Renamed `mac_address` to `node_mac`
- Added credential management (no more hardcoded passwords)

### Example 2: Bulk Node Creation

**Old Command**:
```bash
ansible-playbook bulk_create_pxe_nodes.yml \
  --extra-vars "start_node=10 end_node=19"
```

**New Command**:
```bash
ansible-playbook satellite_node_manager.yml \
  -e operation=bulk \
  -e start_slot=10 \
  -e node_count=10 \
  -e satellite_password=password
```

**Changes**:
- Added `operation=bulk` parameter
- Changed from `start_node/end_node` to `start_slot/node_count`
- Automatic MAC address generation (no manual calculation needed)

### Example 3: First 5 Nodes (Demo)

**Old Command**:
```bash
ansible-playbook first5.yml
```

**New Command**:
```bash
ansible-playbook satellite_node_manager.yml \
  -e operation=bulk \
  -e start_slot=1 \
  -e node_count=5 \
  -e satellite_password=password
```

**Changes**:
- Uses unified bulk operation
- Explicitly specifies count instead of hardcoded
- Requires credentials (more secure)

### Example 4: Batch Creation with Iterations

**Old Command**:
```bash
ansible-playbook build_nodes_in_batches.yml \
  --extra-vars "iterations=3"
```
This created 5 nodes per iteration (15 total).

**New Command**:
```bash
ansible-playbook satellite_node_manager.yml \
  -e operation=bulk \
  -e start_slot=1 \
  -e node_count=15 \
  -e satellite_password=password
```

**Changes**:
- Simplified: Just specify total count
- No need for iteration logic
- More flexible (any count, not just multiples of 5)

### Example 5: Deleting a Node

**Old Command**:
```bash
ansible-playbook delete_pxe_node.yml \
  --extra-vars "node_name=node010"
```

**New Command**:
```bash
ansible-playbook satellite_node_manager.yml \
  -e operation=delete \
  -e node_name=node010 \
  -e confirm_delete=true \
  -e satellite_password=password
```

**Changes**:
- Added `operation=delete` parameter
- Requires `confirm_delete=true` for safety
- Prompts before deletion with pause
- Better error messages if node doesn't exist

### Example 6: Listing Nodes

**Old Command**:
```bash
ansible-playbook list_pxe_nodes.yml
```

**New Command**:
```bash
ansible-playbook satellite_node_manager.yml \
  -e operation=list \
  -e satellite_password=password
```

**Optional Search**:
```bash
ansible-playbook satellite_node_manager.yml \
  -e operation=list \
  -e search_pattern="node1*" \
  -e satellite_password=password
```

**Changes**:
- Added `operation=list` parameter
- Optional search pattern for filtering
- More detailed output (includes IP, MAC, status)

### Example 7: Post-Installation Configuration

**Old Command**:
```bash
ansible-playbook provision_node.yml -i node010.prod.spg,
```

**New Command**:
```bash
ansible-playbook satellite_node_post_install.yml \
  -i node010.prod.spg, \
  -e admin_user=admin \
  -e admin_password=SecurePass123 \
  -e satellite_activation_key=rhel8-compute
```

**Changes**:
- Renamed playbook for clarity
- Requires explicit admin credentials (more secure)
- Requires activation key specification
- Optional system update capability
- Configurable firewall services
- Better error handling with fallbacks

### Example 8: PXE Boot Troubleshooting

**Old Command**:
```bash
ansible-playbook pxe_boot_remediate.yml \
  --extra-vars "host_name=node010.prod.spg vm_name=node010"
```

**New Command**:
```bash
ansible-playbook pxe_boot_troubleshoot.yml \
  -e host_name=node010.prod.spg \
  -e vm_name=node010 \
  -e satellite_password=password
```

**Changes**:
- Renamed for clarity (troubleshoot vs remediate)
- Added credential management
- More detailed diagnostics
- Automatic PXE loader detection and configuration
- inst.stage2 URL reachability testing
- Comprehensive troubleshooting recommendations

## Variable Name Changes

Update your variable files and scripts:

| Old Variable | New Variable | Notes |
|---|---|---|
| mac_address | node_mac | Clearer naming |
| start_node | start_slot | More accurate terminology |
| end_node | node_count | Changed to count-based |
| iterations | node_count | Simplified (just total count) |
| sat_user | satellite_user | Consistent prefix |
| sat_password | satellite_password | Consistent prefix |
| - | operation | New: specifies operation type |
| - | confirm_delete | New: safety confirmation |
| - | search_pattern | New: for filtering lists |

## Credential Management Migration

**Old Approach** (v1.0):
```yaml
# Hardcoded in playbooks
satellite_user: admin
satellite_password: r3dh4t7!
```

**New Approach** (v2.0):

**Option 1 - Environment Variables** (Recommended):
```bash
export SATELLITE_PASSWORD=your_password
ansible-playbook satellite_node_manager.yml -e operation=create ...
```

**Option 2 - Variable Files**:
```yaml
# vars/credentials.yml (add to .gitignore!)
satellite_user: admin
satellite_password: "{{ lookup('env', 'SATELLITE_PASSWORD') }}"
```

```bash
export SATELLITE_PASSWORD=your_password
ansible-playbook satellite_node_manager.yml -e @vars/credentials.yml -e operation=create ...
```

**Option 3 - Ansible Vault**:
```bash
ansible-vault create vars/vault.yml
# Add:
# vault_satellite_password: your_password

ansible-playbook satellite_node_manager.yml \
  -e @vars/vault.yml \
  -e satellite_password="{{ vault_satellite_password }}" \
  -e operation=create ... \
  --ask-vault-pass
```

## Tag Migration

New playbooks support tags for partial execution:

**satellite_node_manager.yml**:
- `validate` - Pre-flight checks only
- `create` - Single node creation
- `bulk` - Bulk operations
- `delete` - Node deletion
- `list` - Node listing

**satellite_node_post_install.yml**:
- `admin` - Admin user configuration
- `ssh` - SSH configuration
- `hostname` - Hostname setup
- `satellite` - Satellite registration
- `firewall` - Firewall configuration
- `update` - System updates

**Examples**:
```bash
# Only validate without making changes
ansible-playbook satellite_node_manager.yml --tags validate -e operation=create ...

# Only configure SSH on nodes
ansible-playbook satellite_node_post_install.yml --tags ssh -i nodes.ini ...

# Skip system updates
ansible-playbook satellite_node_post_install.yml --skip-tags update -i nodes.ini ...
```

## Error Handling Migration

**Old Behavior**:
- Commands failed silently
- No retry on network issues
- Cryptic error messages
- No troubleshooting guidance

**New Behavior**:
- Comprehensive error messages with context
- Automatic retry (3 attempts by default)
- Rescue blocks with troubleshooting steps
- Pre-flight validation

**Configure Retry Behavior**:
```yaml
api_retry_count: 5        # Number of attempts
api_retry_delay: 10       # Seconds between attempts
```

## Inventory Changes

**Old Requirements**:
- Playbooks assumed specific inventory structure
- Hardcoded group names

**New Requirements**:

For **satellite_node_manager.yml**:
- Runs against `satellite` group or localhost with delegate_to
- Can specify target in playbook invocation

For **satellite_node_post_install.yml**:
- Runs against target nodes directly
- Specify nodes in inventory or with `-i`

For **pxe_boot_troubleshoot.yml**:
- Requires `kvm` group with KVM hypervisor
- Requires `satellite` group with Satellite server

**Example Inventory** (inventory/hosts.ini):
```ini
[kvm]
kaso.prod.spg

[satellite]
satellite.prod.spg

[new_nodes]
node010.prod.spg
node011.prod.spg
node012.prod.spg
```

## Workflow Migration

**Old Workflow**:
```bash
# 1. Create nodes (separate playbooks)
ansible-playbook bulk_create_pxe_nodes.yml --extra-vars "start_node=10 end_node=14"

# 2. If boot fails, troubleshoot
ansible-playbook pxe_boot_remediate.yml --extra-vars "host_name=node010.prod.spg vm_name=node010"

# 3. Wait for installation, then provision
ansible-playbook provision_node.yml -i node010.prod.spg,
# Repeat for each node...

# 4. Verify
ansible-playbook list_pxe_nodes.yml
```

**New Workflow**:
```bash
# 1. Create nodes (unified playbook)
ansible-playbook satellite_node_manager.yml \
  -e operation=bulk \
  -e start_slot=10 \
  -e node_count=5

# 2. If boot fails, troubleshoot
ansible-playbook pxe_boot_troubleshoot.yml \
  -e host_name=node010.prod.spg \
  -e vm_name=node010

# 3. Wait for installation, then provision all nodes in parallel
ansible-playbook satellite_node_post_install.yml \
  -i nodes.ini \
  -e admin_user=admin \
  -e admin_password=SecurePass123 \
  -e satellite_activation_key=rhel8-compute \
  -f 5

# 4. Verify
ansible-playbook satellite_node_manager.yml \
  -e operation=list \
  -e search_pattern="node1*"
```

**Key Improvements**:
- Fewer commands
- Parallel post-install (instead of serial)
- Better verification with search
- Unified credential management

## Automation Script Migration

If you have automation scripts, update them:

**Old Script**:
```bash
#!/bin/bash
# create_lab_nodes.sh

START=100
END=109

for i in $(seq $START $END); do
  NODE_NAME="node$(printf %03d $i)"
  MAC="52:54:00:00:00:$(printf %02x $i)"
  
  ansible-playbook create_pxe_node.yml \
    --extra-vars "node_name=$NODE_NAME mac_address=$MAC"
done
```

**New Script**:
```bash
#!/bin/bash
# create_lab_nodes.sh

START=100
COUNT=10

# Use bulk operation instead of loop
ansible-playbook satellite_node_manager.yml \
  -e operation=bulk \
  -e start_slot=$START \
  -e node_count=$COUNT \
  -e satellite_password="${SATELLITE_PASSWORD}"
```

**Benefits**:
- Much faster (API optimized for bulk)
- Simpler code
- Better error handling
- Atomic operation (all succeed or fail together)

## Testing Your Migration

Follow these steps to test the migration:

### Step 1: Test Single Node Creation

```bash
# Create test node
ansible-playbook satellite_node_manager.yml \
  -e operation=create \
  -e node_name=test001 \
  -e node_mac=52:54:00:AA:BB:01 \
  -e satellite_password=password

# Verify
ansible-playbook satellite_node_manager.yml \
  -e operation=list \
  -e search_pattern="test*"
```

### Step 2: Test PXE Troubleshooting

```bash
ansible-playbook pxe_boot_troubleshoot.yml \
  -e host_name=test001.prod.spg \
  -e vm_name=test001 \
  -e satellite_password=password
```

### Step 3: Test Post-Install (After OS Installation)

```bash
ansible-playbook satellite_node_post_install.yml \
  -i test001.prod.spg, \
  -e admin_user=testadmin \
  -e admin_password=TestPass123 \
  -e satellite_activation_key=rhel8-compute
```

### Step 4: Test Deletion

```bash
ansible-playbook satellite_node_manager.yml \
  -e operation=delete \
  -e node_name=test001 \
  -e confirm_delete=true \
  -e satellite_password=password
```

### Step 5: Test Bulk Operations

```bash
# Create 3 test nodes
ansible-playbook satellite_node_manager.yml \
  -e operation=bulk \
  -e start_slot=901 \
  -e node_count=3 \
  -e satellite_password=password

# List them
ansible-playbook satellite_node_manager.yml \
  -e operation=list \
  -e search_pattern="node90*"

# Delete them
for i in {901..903}; do
  ansible-playbook satellite_node_manager.yml \
    -e operation=delete \
    -e node_name=node${i} \
    -e confirm_delete=true \
    -e satellite_password=password
done
```

## Rollback Plan

If you need to rollback to old playbooks:

1. Old playbooks are preserved in `archive/` directory
2. Restore them:
   ```bash
   cp archive/*.yml .
   ```

3. Update your scripts to use old commands

Note: The old playbooks still have the original issues (hardcoded credentials, no error handling, etc.)

## Getting Help

If you encounter issues during migration:

1. **Check Documentation**: Review [README.md](README.md) for detailed usage
2. **Use Verbose Mode**: Run with `-vvv` for detailed output
3. **Test Credentials**: Verify API access:
   ```bash
   curl -u admin:password -k https://satellite.prod.spg/api/status
   ```

4. **Check Tags**: Use `--tags validate` to test without making changes
5. **Review Logs**:
   - Satellite: `/var/log/foreman/production.log`
   - Ansible: Use `-vvv` flag

## Benefits Summary

After migration, you get:

- 70% fewer files (3 vs 10 playbooks)
- API-based operations (more reliable than shell)
- Comprehensive error handling (retry logic, rescue blocks)
- No hardcoded credentials (secure by default)
- Conditional execution (tags for partial runs)
- Better troubleshooting (detailed error messages)
- Parallel execution support (faster deployments)
- Unified interface (single playbook, multiple operations)
- Fallback options (graceful degradation)
- Pre-flight validation (catch errors early)

## Migration Checklist

- [ ] Review new playbook documentation (README.md)
- [ ] Update automation scripts with new commands
- [ ] Migrate hardcoded credentials to environment variables or vault
- [ ] Update variable names in your files
- [ ] Test single node creation
- [ ] Test bulk node creation
- [ ] Test post-install configuration
- [ ] Test PXE troubleshooting
- [ ] Test deletion operations
- [ ] Update documentation/runbooks
- [ ] Train team on new playbooks
- [ ] Archive old playbooks
- [ ] Update CI/CD pipelines
- [ ] Verify all integrations work

## Next Steps

1. Complete testing with non-production nodes
2. Update your documentation and runbooks
3. Train team members on new playbooks
4. Gradually migrate production workflows
5. Archive old playbooks when confident

For questions or issues, refer to [README.md](README.md) troubleshooting section.

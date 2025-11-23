# AnsibleSatellite Playbooks

Automated provisioning and configuration of Red Hat Satellite hosts and related infrastructure. This repository contains playbooks for node provisioning, Satellite configuration, AAP integration, and libvirt operations.

For a categorized list of playbooks, see `playbooks/PLAYBOOK_INDEX.md`.

## Repository layout

```
playbooks/
  node_provisioning/
  satellite_configuration/
  ansible_configuration/
  libvirt_configuration/
```

## Quickstart

This sequence sets up the kickstart post section, associates it to RHEL 9.7, configures required global parameters, builds hosts in bulk, and verifies the post install summary file.

Prerequisites
- Ansible is installed on the control node
- A Satellite server is reachable at your chosen hostname
- API credentials available (export password as an environment variable)
- Your controller user can write to the chosen export directory if using CSV export

1. Export secrets

```bash
export SATELLITE_PASSWORD='yourpassword'
```

2. Push the provisioning template to Satellite

```bash
ansible-playbook playbooks/node_provisioning/push_provisioning_template.yml \
  -e satellite_host=satellite.prod.spg \
  -e satellite_username=admin \
  -e satellite_password="$SATELLITE_PASSWORD"
```

3. Associate template to RHEL 9.7 and set it as default

```bash
ansible-playbook playbooks/node_provisioning/associate_template_to_os.yml \
  -e satellite_host=satellite.prod.spg \
  -e satellite_username=admin \
  -e satellite_password="$SATELLITE_PASSWORD" \
  -e os_major=9 -e os_minor=7
```

4. Create or update required Foreman parameters

```bash
ansible-playbook playbooks/node_provisioning/set_foreman_parameters.yml \
  -e satellite_host=satellite.prod.spg \
  -e satellite_username=admin \
  -e satellite_password="$SATELLITE_PASSWORD" \
  -e admin_user=admin \
  -e admin_password='StrongPass' \
  -e activation_keys='{"9":"RHEL9-AK"}' \
  -e ks_enable_updates=true
```

5. Build hosts in bulk

Use numeric IDs or provide names to auto resolve IDs. The example below uses names, enables random MAC last octet, and writes a CSV.

```bash
ansible-playbook playbooks/node_provisioning/bulk_node_builder.yml \
  -e node_count=5 \
  -e node_prefix=node \
  -e domain=prod.spg \
  -e os_name='RHEL 9.7' \
  -e hostgroup_name='Base' \
  -e subnet_name='Provisioning' \
  -e location_name='Denver' \
  -e organization_name='Default Organization' \
  -e random_mac=true \
  -e export_path=/tmp/bulk_nodes.csv \
  -e satellite_host=satellite.prod.spg \
  -e satellite_user=admin \
  -e satellite_password="$SATELLITE_PASSWORD"
```

6. Verify the post install summary on a newly provisioned node

```bash
ansible-playbook playbooks/node_provisioning/verify_post_install_summary.yml \
  -e target_host=node001.prod.spg \
  -e ssh_user=root
```

7. Troubleshoot PXE boot if needed

```bash
ansible-playbook playbooks/node_provisioning/pxe_boot_troubleshoot.yml \
  -e host_name=node001.prod.spg \
  -e vm_name=node001 \
  -e kvm_uri=qemu:///system
```

8. Clean up a host

```bash
ansible-playbook playbooks/node_provisioning/satellite_node_manager.yml \
  -e operation=delete \
  -e node_name=node001.prod.spg \
  -e satellite_host=satellite.prod.spg \
  -e satellite_user=admin \
  -e satellite_password="$SATELLITE_PASSWORD"
```

## Core playbooks

Node provisioning (playbooks/node_provisioning)
- satellite_node_manager.yml: Unified CRUD for Satellite hosts. Supports auto slot selection, random MAC option, name based ID lookup, CSV export.
- bulk_node_builder.yml: Survey driven high volume host creation with sequential or gap numbering, concurrency tuning, optional CSV export. Supports name based ID lookup and random MAC option.
- push_provisioning_template.yml: Create or update the kickstart post template on Satellite.
- associate_template_to_os.yml: Associate the provisioning template with RHEL OS (major, minor) as default.
- set_foreman_parameters.yml: Create or update global parameters used by the %post logic.
- verify_post_install_summary.yml: Wait for SSH and confirm /root/post-install-summary.txt exists.
- pxe_boot_troubleshoot.yml: Diagnostics and fixes for PXE boot issues.

Satellite configuration (playbooks/satellite_configuration)
- satellite_configuration_manager.yml and related: Health checks, configuration management, email setup, compute profile fixes.

Ansible configuration (playbooks/ansible_configuration)
- configure_aap_job_templates.yml: Create or update AAP job templates and surveys.
- setup_satellite_aap_integration.yml: Establish trust and inventory between Satellite and AAP.

Libvirt configuration (playbooks/libvirt_configuration)
- cleanup_orphaned_disks.yml: Identify and remove unused libvirt volumes.

## AAP survey suggestions

For bulk_node_builder.yml consider the following survey fields.

- node_count: integer, default 5
- node_prefix: text, default node
- domain: text, default prod.spg
- sequential_mode: boolean, default true
- number_padding: integer, default 3
- build_strategy: choice linear or free, default linear
- serial_batch: integer, default 0
- mac_address_prefix: text, default 52:54:00:aa:bb
- random_mac: boolean, default false
- satellite_host: text
- satellite_user: text
- satellite_password: password
- os_id, hostgroup_id, subnet_id, location_id, organization_id: integers
- os_name, hostgroup_name, subnet_name, location_name, organization_name: text
- export_path: text (controller local path)

## Security notes

- Provide Satellite credentials via environment variables or Controller credentials. Example: export SATELLITE_PASSWORD.
- Do not store private SSH keys in this repository. Public keys only when needed.
- The post install template does not copy private keys. It aggregates public keys only.

## Troubleshooting notes

- Use pxe_boot_troubleshoot.yml to resolve boot file and loader issues. It detects OS, validates expected files, and creates symlinks if required.
- If name based lookup fails for any resource, the playbooks abort early with a clear message. You can fall back to numeric IDs.
- For very large builds reduce API pressure by using serial_batch and strategy linear, or keep strategy free and increase Controller forks within safe limits.

## Requirements

- Ansible 2.12 or later
- Python 3.x on the control node
- Satellite 6.x reachable over HTTPS
- Optional: libvirt tools if using PXE troubleshooting with virsh

## Additional references

- See `playbooks/PLAYBOOK_INDEX.md` for a categorized list and synopsis of all major playbooks.

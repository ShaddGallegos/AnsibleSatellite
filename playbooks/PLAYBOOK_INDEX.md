# Playbook Index

Consolidated reference of primary playbooks by category with synopsis, key variables, and typical usage patterns.

## Node Provisioning
| Playbook | Path | Synopsis | Key Vars |
|----------|------|----------|----------|
| Satellite Node Manager | node_provisioning/satellite_node_manager.yml | CRUD: create, bulk, delete, list PXE/Satellite hosts with slot & MAC mgmt | operation, mac_address, node_count, satellite_user/password |
| Bulk Node Builder | node_provisioning/bulk_node_builder.yml | Survey-driven bulk creation with sequential/gap numbering, concurrency tuning, name-based ID lookup, optional random MAC, CSV export | node_count, build_strategy, sequential_mode, number_padding, serial_batch, os_name/hostgroup_name/etc, random_mac, export_path |
| PXE Boot Troubleshoot | node_provisioning/pxe_boot_troubleshoot.yml | Deep PXE diagnostics (VM, TFTP, kernel opts, repo reachability) + remediation | vm_name, host_name, kvm_uri, satellite_password |
| Post-Install Node Config | node_provisioning/satellite_node_post_install.yml | Finalize freshly provisioned nodes (user, registration, firewall, optional updates) | admin_user/password, activation_keys, enable_root_login |
| Verify Post-Install Summary | node_provisioning/verify_post_install_summary.yml | Wait for SSH and confirm /root/post-install-summary.txt presence | target_host, ssh_user |
| Push Provisioning Template | node_provisioning/push_provisioning_template.yml | Idempotent create/update of ERB provisioning template via API | template_name, template_file, satellite_username/password |
| Associate Template to OS | node_provisioning/associate_template_to_os.yml | Map provisioning template as default for RHEL OS (major/minor) | template_name, os_major, os_minor |
| Set Foreman Parameters | node_provisioning/set_foreman_parameters.yml | Upsert global params consumed by %post (admin_user/password, activation_keys) | admin_user, admin_password, activation_keys, ks_enable_updates |
| Create Post Template (Clean) | node_provisioning/create_satellite_post_template_clean.yml | Assemble enhanced RHEL 9.7 post-kickstart template directly on Satellite | sat_existing_template_path, sat_new_template_path, admin_user/password |

## Satellite Configuration
| Playbook | Path | Synopsis | Key Vars |
|----------|------|----------|----------|
| Configuration Manager | satellite_configuration/satellite_configuration_manager.yml | Manage compute profiles, discover defaults, fix PXE templates | operation, compute_resource_id, pxe_bridge |
| Health Monitoring & Backup | satellite_configuration/satellite_health_monitoring.yml | Health checks + config backup with retention policies | operation, backup_root, backup_retention_days |
| Email Notifications | satellite_configuration/satellite_email_notifications.yml | Configure Postfix/Gmail fallback and send/verify notifications | operation, smtp_host, smtp_account, gmail_enabled |

## Ansible Configuration / AAP Integration
| Playbook | Path | Synopsis | Key Vars |
|----------|------|----------|----------|
| Configure AAP Job Templates | ansible_configuration/configure_aap_job_templates.yml | Create/update Controller job templates, inventories, surveys | controller_host, organization_name, job_templates |
| Setup Satellite–AAP Integration | ansible_configuration/setup_satellite_aap_integration.yml | Establish trust & inventory source between Satellite and AAP | satellite_ca_path, controller_host, inventory parameters |

## Libvirt / KVM
| Playbook | Path | Synopsis | Key Vars |
|----------|------|----------|----------|
| Cleanup Orphaned Disks | libvirt_configuration/cleanup_orphaned_disks.yml | Identify & remove unused libvirt disk volumes | kvm_host, domain_pattern |

## Usage Patterns
- Always export sensitive passwords as environment variables (e.g. `export SATELLITE_PASSWORD=...`).
- Prefer dry-run modes where available (`bulk_node_builder.yml` with `dry_run=true`).
- Use confirmation pauses for safety in bulk operations (node creation & deletion).
- For template lifecycle: push → associate → set params → provision host → verify summary.

## Recommended Survey Fields (Bulk Node Builder)
```
node_count (int)            How many nodes
node_prefix (text)          Base host name prefix (default node)
sequential_mode (bool)      Extend from highest existing (true) or fill gaps (false)
number_padding (int)        Zero padding width (e.g. 3 => node007)
build_strategy (choice)     linear|free
serial_batch (int)          Batch size throttle (0 = all)
mac_address_prefix (text)   First 5 MAC octets
random_mac (bool)           Pseudo-randomize MAC last octet (time+slot)
max_node_count (int)        Safety cap
require_confirmation (bool) Pause before starting
confirmation_timeout (int)  Seconds to wait
satellite_host (text)       Satellite FQDN
satellite_user (text)       API username
satellite_password (password) API password
os_id, hostgroup_id, subnet_id, location_id, organization_id (int) Resource IDs
os_name, hostgroup_name, subnet_name, location_name, organization_name (text) Resolve IDs by name
export_path (text)          Write CSV summary (controller local path)
```

## Template Lifecycle Quick Reference
1. Build or update template: `push_provisioning_template.yml`
2. Associate to OS: `associate_template_to_os.yml`
3. Set global parameters: `set_foreman_parameters.yml`
4. Provision hosts (bulk or manager playbooks)
5. Validate `%post`: `verify_post_install_summary.yml`

## File Naming Conventions
- Slots padded per environment standard (`number_padding`).
- MAC addresses derived using prefix + slot hex suffix.
- Clean template creation kept separate from legacy logic (`create_satellite_post_template_clean.yml`).

## Decommissioned / Replaced
- Legacy `create_satellite_post_template.yml` removed in favor of `create_satellite_post_template_clean.yml`.

## Future Enhancement Ideas
- Enhanced MAC uniqueness (multi-octet randomization & collision checks)
- Async host creation with polling and timeout control
- JSON export alternative to CSV
- Automatic tagging/grouping of exported hosts for follow-on plays

## Security Notes
- No private key material persisted; only public keys aggregated.
- Use Ansible Vault or credentials in Controller for sensitive values.
- Activation keys mapped by OS major version string.

---
Last updated: {{ DATE_PLACEHOLDER }}

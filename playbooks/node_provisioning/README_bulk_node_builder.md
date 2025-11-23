# Bulk Node Builder

High-performance, survey-driven bulk creation of Satellite hosts with tunable execution parameters for Ansible Automation Platform (AAP).

## Purpose

Enable rapid provisioning of many similarly structured nodes while allowing an operator (via AAP Survey) to adjust concurrency, batching, and safety controls without editing code.

## Key Features

- Dynamic slot selection based on existing hosts
- Strategy toggle: linear vs free (parallel execution)
- Optional serial batching to throttle API pressure
- Dry-run preview mode
- MAC auto-generation using slot number for uniqueness (last octet)
- Safety caps (max_node_count) and confirmation pauses
- Minimal required parameters for quick adoption

## Recommended AAP Job Template Survey Fields

| Variable | Type | Default | Required | Help | Choices / Range |
|----------|------|---------|----------|------|-----------------|
| node_count | Integer | 5 | Yes | Number of nodes to create | 1-50 |
| start_slot | Integer | (auto) | No | Override starting number (else auto/sequential) | 1-999 |
| node_prefix | Text | node | Yes | Base host name prefix | |
| domain | Text | prod.spg | Yes | Domain suffix | |
| mac_address_prefix | Text | 52:54:00:aa:bb | Yes | First 5 MAC octets | Must be 5 octets |
| max_node_count | Integer | 50 | Yes | Safety cap to prevent overload | 1-200 |
| build_strategy | Multiple Choice | linear | Yes | Execution strategy | linear, free |
| serial_batch | Integer | 0 | No | Batch size (0 = all) | 0-100 |
| sequential_mode | Boolean | true | Yes | Extend from highest existing (true) or fill gaps (false) | true/false |
| number_padding | Integer | 3 | Yes | Zero-pad width for numeric part | 1-6 |
| require_confirmation | Boolean | true | Yes | Pause before creating | true/false |
| confirmation_timeout | Integer | 5 | Yes | Seconds to pause | 0-120 |
| dry_run | Boolean | false | Yes | Plan only; no API create | true/false |
| satellite_host | Text | satellite.prod.spg | Yes | Satellite FQDN | |
| satellite_user | Text | admin | Yes | API username | |
| satellite_password | Password | (vault/env) | Yes | API password | |
| os_id | Integer | 1 | Yes | Operating System ID | |
| hostgroup_id | Integer | 1 | Yes | Hostgroup ID | |
| subnet_id | Integer | 1 | Yes | Subnet ID | |
| location_id | Integer | 2 | Yes | Location ID | |
| organization_id | Integer | 1 | Yes | Organization ID | |
| os_name | Text | (blank) | No | Resolve OS ID by name (if set, overrides os_id) | |
| hostgroup_name | Text | (blank) | No | Resolve hostgroup ID by name | |
| subnet_name | Text | (blank) | No | Resolve subnet ID by name | |
| location_name | Text | (blank) | No | Resolve location ID by name | |
| organization_name | Text | (blank) | No | Resolve organization ID by name | |
| random_mac | Boolean | false | No | Pseudo-randomize MAC last octet (time+slot) | true/false |
| export_path | Text | (blank) | No | Write CSV summary to path (controller local) | |

Notes:
- Leave `start_slot` blank to use the first available slot.
- Use `dry_run=true` first to validate plan without creating hosts.
- Increase Job Template forks when using `build_strategy=free` (e.g., 20 or 30) for higher concurrency.
- Use `serial_batch` to throttle creation (e.g., 5) if Satellite API becomes saturated.
- Job slicing (AAP feature) can further distribute load across controller workers.
- You may provide either numeric IDs (`os_id`, etc.) OR names (`os_name`, etc.). When a name is supplied its resolved ID overrides the numeric value.
- `random_mac=true` alters MAC generation by replacing the slot-derived last octet with a time+slot pseudo-random value.
- Set `export_path` (e.g. `/tmp/bulk_nodes.csv`) to emit a CSV of results: name,id,mac,slot,timestamp,status.

## Example Run (Linear Strategy)

```bash
export SATELLITE_PASSWORD='mypassword'
ansible-playbook bulk_node_builder.yml \
  -e node_count=10 -e build_strategy=linear -e confirmation_timeout=3
```

## Example Run (Free Strategy with Serial Batching)

```bash
export SATELLITE_PASSWORD='mypassword'
ansible-playbook bulk_node_builder.yml \
  -e node_count=20 -e build_strategy=free -e serial_batch=5 -e confirmation_timeout=5
```

## Dry Run Preview

```bash
ansible-playbook bulk_node_builder.yml -e node_count=8 -e dry_run=true
```

Output includes planned node names and MACs without creation.

## Sequential Mode vs Gap Fill

- When `sequential_mode=true` (default) the playbook finds the highest existing numeric suffix and starts at that + 1 to produce a contiguous sequence (ignoring earlier gaps). For example, if the highest existing node is `node101` and you request 20 nodes, they will be `node102` through `node121` (or `node122` if counting inclusively based on start slot and count).
- When `sequential_mode=false` the playbook fills from the first available gap starting at the auto-selected slot; this can reuse earlier numbers if holes exist.

To override starting number explicitly, set `start_slot`. This takes precedence over sequential/gap logic.

## Number Padding

Hostnames use zero padding defined by `number_padding`. For example:

| Padding | Slot 7 | Slot 102 |
|---------|--------|----------|
| 2 | node07 | node102 |
| 3 | node007 | node102 |
| 4 | node0007 | node0102 |

Adjust padding to match existing naming conventions. Setting padding lower than existing widths is safe; previously created hosts are still discovered via a 3-digit pattern, so for mixed widths ensure consistency or adjust discovery logic if needed.

## MAC Generation Logic

Each node derives a MAC by appending the slot number (hex) to the prefix:

```
<mac_address_prefix>:<slot_hex>
Example slot 37 (0x25): 52:54:00:aa:bb:25
```

Adjust the prefix to reflect your environment or ensure uniqueness across virtualization platforms.

### Random MAC Option

When `random_mac=true` the final MAC octet is computed as `(epoch_timestamp + slot) % 256` instead of the slot number. This provides pseudo-uniqueness while keeping deterministic behavior per run. Use when you prefer to avoid visually sequential MACs; retain deterministic generation (`random_mac=false`) for easier correlation.

Uniqueness caveat: For very large concurrent runs within the same second, collisions are unlikely but theoretically possible if `(epoch + slot)` produces identical modulo results. For production-critical uniqueness rely on deterministic slot-based MACs or integrate a more robust MAC allocation strategy.

## Automatic Resource ID Lookup By Name

Supplying any of the *_name variables (e.g. `os_name`, `hostgroup_name`) triggers an API lookup before planning. The corresponding *_id value is overridden. This reduces required survey fields—operational teams can reference canonical names without tracking numeric IDs.

Resolution order:
1. If *_name provided, perform API search `?search=name=<value>`.
2. Assert at least one result; use first match's ID.
3. Fall back to explicit *_id when name not given.

Failure modes (name not found) cause an assertion failure early, preventing partial creation.

## CSV Export

Define `export_path` to write a CSV summary on the controller host after completion. Columns:

```
name,id,mac,slot,timestamp,status
```

`id` is blank for dry-run. `status` is `CREATED`, `FAILED`, or `DRY-RUN`. Useful for audit trails, importing into spreadsheets, or feeding subsequent automation.

## Performance Tuning Tips

| Lever | Effect | Guidance |
|-------|--------|----------|
| build_strategy=free | Parallel tasks | Use when Satellite API can handle concurrency |
| forks (Job Template) | Parallel host task execution | Set >= node_count for max speed (capped by controller limits) |
| serial_batch | Limits simultaneous hosts | Use to avoid API saturation or DB lock contention |
| job slicing | Distributes across controller capacity | Ideal for very large (>100) node builds |
| dry_run | Planning only | Use before large runs to confirm slot & MAC mapping |

## Safety Considerations

- `max_node_count` prevents accidental large-scale creation.
- Confirmation pause provides an abort window.
- Recommended to run during low Satellite load or maintenance windows for large batches.

## Post-Creation Validation

After creation, confirm hosts and build state:

```bash
hammer host list | grep node
```

Or query API directly:

```bash
curl -k -u admin:"$SATELLITE_PASSWORD" https://satellite.prod.spg/api/hosts?search=name~node
```

## Integration With Post-Install

Combine this playbook with the RHEL 9.7 post-kickstart template and verification playbook (`verify_post_install_summary.yml`) to ensure consistent configuration and logging on first boot.

## Troubleshooting

| Symptom | Cause | Resolution |
|---------|-------|-----------|
| Many failures, HTTP 422 | Invalid resource IDs | Verify os_id, hostgroup_id, subnet_id, etc. via hammer |
| Timeouts or API errors | Satellite under load | Lower forks or use serial_batch to throttle |
| Duplicate MAC errors | Overlapping MAC range | Adjust mac_address_prefix or slot mapping |
| Insufficient slots error | Slots occupied | Increase start_slot or delete unused hosts |

## Next Enhancements (Ideas)

- Enhanced MAC uniqueness strategy (multi-octet randomization with collision checks)
- Async mode with progress polling
- JSON export variant alongside CSV
- Automatic grouping/tagging of exported hosts for subsequent playbooks

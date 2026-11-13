# THG patches for v56.2.0

## v56.2.0-thg-r8 — native Cloud SQL maintenance target

Adds nullable `maintenance_version` to `modules/cloudsql-instance` and passes it
to `google_sql_database_instance.primary` only. Exposes primary installed and
available maintenance-version outputs. Existing callers default to null;
replicas receive no independent target. Google handles associated replica
maintenance when the primary is updated.

The patch is based on `v56.2.0-thg-r7` on `thg/v56.2.0-custom`, preserving prior
THG patches. It does not change provider version requirements. Workload Factory
performs live target validation and reports disruption before apply.

Mocked Terraform tests cover explicit primary pass-through, default omission,
primary outputs and replica isolation. They do not submit live maintenance.

For earlier revisions, consult the immutable `v56.2.0-thg-r1` through
`v56.2.0-thg-r7` tags and their commit history.

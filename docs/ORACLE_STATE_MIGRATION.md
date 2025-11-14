# Oracle Instance State Migration

Terraform cannot map multiple historical resource addresses to the same
`oci_core_instance.instances["<name>"]` destination: the `moved` block syntax rejects
duplicate `to` addresses. The current configuration therefore includes automatic moves only
for the most recent rename (`instances["pam-*"]` back to `instances["amd*/arm*"]`). If your
environment still uses the pre-for_each resources (`oci_core_instance.amd1`, etc.) you must
run the following `terraform state mv` commands once before applying the latest code:

```bash
terraform state mv oci_core_instance.amd1   'oci_core_instance.instances["amd1"]'
terraform state mv oci_core_instance.amd2   'oci_core_instance.instances["amd2"]'
terraform state mv oci_core_instance.arm1   'oci_core_instance.instances["arm1"]'
terraform state mv oci_core_instance.arm2   'oci_core_instance.instances["arm2"]'
```

After migrating the state, run `terraform plan` to verify that Terraform no longer proposes
to destroy and recreate the Oracle instances. Future renames (such as the friendly-name
experiment) are covered by the in-repo `moved` blocks, so no further manual action should
be required.

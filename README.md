# Remote developement environment

This module creates an OS Login-enabled VM instance that can be used as a
remote environment for VSCode.

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_github"></a> [github](#requirement\_github) | ~> 4.0 |
| <a name="requirement_google"></a> [google](#requirement\_google) | 4.14.0 |
| <a name="requirement_tls"></a> [tls](#requirement\_tls) | 3.1.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_google"></a> [google](#provider\_google) | 4.14.0 |
| <a name="provider_tls"></a> [tls](#provider\_tls) | 3.1.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_cloud-nat"></a> [cloud-nat](#module\_cloud-nat) | terraform-google-modules/cloud-nat/google | ~> 1.2 |

## Resources

| Name | Type |
|------|------|
| [google_compute_firewall.iap](https://registry.terraform.io/providers/hashicorp/google/4.14.0/docs/resources/compute_firewall) | resource |
| [google_compute_instance.vm](https://registry.terraform.io/providers/hashicorp/google/4.14.0/docs/resources/compute_instance) | resource |
| [google_compute_instance_iam_member.os_login](https://registry.terraform.io/providers/hashicorp/google/4.14.0/docs/resources/compute_instance_iam_member) | resource |
| [google_compute_network.default](https://registry.terraform.io/providers/hashicorp/google/4.14.0/docs/resources/compute_network) | resource |
| [google_compute_subnetwork.default](https://registry.terraform.io/providers/hashicorp/google/4.14.0/docs/resources/compute_subnetwork) | resource |
| [google_os_login_ssh_public_key.dev](https://registry.terraform.io/providers/hashicorp/google/4.14.0/docs/resources/os_login_ssh_public_key) | resource |
| [google_service_account.default](https://registry.terraform.io/providers/hashicorp/google/4.14.0/docs/resources/service_account) | resource |
| [tls_private_key.dev](https://registry.terraform.io/providers/hashicorp/tls/3.1.0/docs/resources/private_key) | resource |
| [google_client_openid_userinfo.me](https://registry.terraform.io/providers/hashicorp/google/4.14.0/docs/data-sources/client_openid_userinfo) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_project_id"></a> [project\_id](#input\_project\_id) | (Required) The project ID to deploy to. | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | (Optional. Defaults to europe-west2) The region to deploy to. | `string` | `"europe-west2"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_ssh_config"></a> [ssh\_config](#output\_ssh\_config) | n/a |

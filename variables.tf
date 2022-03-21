variable "region" {
  description = "(Optional. Defaults to europe-west2) The region to deploy to."
  type        = string
  default     = "europe-west2"
}
variable "project_id" {
  description = "(Required) The project ID to deploy to."
  type        = string
}
variable "git_name" {
  description = "(Required) The name used for Git config"
  type        = string
}

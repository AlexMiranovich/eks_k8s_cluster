#eks vars
variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-2"
}

variable "owner" {
  description = "1M Sol"
  type        = string
  default     = "mir92on@gmail.com"
}

variable "cluster_environment" {
  type        = string
  default     = "dev"
}

#ecr vars
variable "name" {
  description = "Repository name"
  type        = string
  default     = "1M_Sol_repo"
}

variable "force_delete" {
  type        = bool
  default     = false
}

variable "image_tag_mutability" {
  type        = string
  default     = "MUTABLE"
  validation {
    condition     = contains(["MUTABLE", "IMMUTABLE"], var.image_tag_mutability)
    error_message = "The image_tag_mutability must be either MUTABLE or IMMUTABLE."
  }
}

# encryption type
variable "encryption_type" {
  description = "The encryption type to use for the repository. Valid values are `AES256` or `KMS`"
  type        = string
  default     = "AES256"
  validation {
    condition     = contains(["AES256", "KMS"], var.encryption_type)
    error_message = "The encryption_type must be either AES256 or KMS."
  }
}

# kms key
variable "kms_key" {
  description = "The ARN of the KMS key to use when encryption_type is `KMS`. If not specified when encryption_type is `KMS`, uses a new KMS key. Otherwise, uses the default AWS managed key for ECR."
  type        = string
  default     = null
}

variable "image_scanning_configuration" {
  description = "Configuration block that defines image scanning configuration for the repository. By default, image scanning must be manually triggered. See the ECR User Guide for more information about image scanning."
  type        = map(any)
  default     = null
}

variable "timeouts" {
  description = "Timeouts map"
  type        = map(any)
  default     = {}
}

variable "timeouts_delete" {
  description = "How long to wait for a repository to be deleted."
  type        = string
  default     = null
}

variable "scan_on_push" {
  description = "Indicates whether images are scanned after being pushed to the repository (true) or not scanned (false)."
  type        = bool
  default     = true
}

variable "tags" {
  description = "A mapping of tags to assign to the resource."
  type        = map(string)
  default     = {}
}

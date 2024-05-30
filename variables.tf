# OVERALL PROJECT VARIABLES

variable "project" {
  description = "Project"
  default     = "septa-pipeline"
}

variable "region" {
  description = "Region"
  default     = "us-central1"
}

variable "location" {
  description = "Project Location"
  default     = "US"
}

variable "credentials" {
  description = "My Credentials"
  default     = "./keys/service_acct_creds.json"
}

variable "public_ssh_key_path" {
  description = "Path to the public SSH key to be used for VM access"
  default     = "~/.ssh/gcloud_key.pub"
}

variable "ssh_user" {
  description = "Username for SSH access"
  default     = "dan.r.lucas"
}


# SERVICE-SPECIFIC VARIABLES

# DATAPROC CLUSTER
variable "cluster_name" {
  description = "name for dataproc cluster"
  default     = "septa_cluster"
}

variable "zoomcamp_service_account_email" {
  description = "email linked to gcloud project service account - reads from tfvars"
  type        = string
}

# BIGQUERY DWH
variable "bq_dataset_name" {
  description = "My BigQuery Dataset Name"
  default     = "ny_taxi_dataset"
}

# CLOUD STORAGE
variable "gcs_bucket_name" {
  description = "My Storage Bucket Name"
  default     = "ny_taxi_storage_413811"
}

variable "gcs_storage_class" {
  description = "Bucket Storage Class"
  default     = "STANDARD"
}


# COMPUTE ENGINE
variable "startup_script" {
  description = "VM startup script"
  default     = "./startup.sh"
}


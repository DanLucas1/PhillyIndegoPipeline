# OVERALL PROJECT VARIABLES
variable "location" {
  description = "Project Location"
  default     = "US"
}

variable "credentials" {
  description = "Credentials for Terraform service account"
  default     = "./keys/tf_service_acct_creds.json"
}

variable "region" {
  type        = string
  description = "The default compute region"
  default     = "us-central1"
}

variable "zone" {
  type        = string
  description = "The default compute zone"
  default     = "us-central1-b"
}

# CLOUD RUN VARIABLES
variable "app_name" {
  type        = string
  description = "Application Name"
  default     = "indego-pipeline"
}

variable "container_cpu" {
  description = "Container cpu"
  default     = "2000m"
}

variable "container_memory" {
  description = "Container memory"
  default     = "2G"
}

variable "project_id" {
  type        = string
  description = "Indego Bikeshare Pipeline"
  default     = "indego-pipeline"
}

variable "repository" {
  type        = string
  description = "The name of the Artifact Registry repository to be created"
  default     = "artifact-registry"
}

variable "database_user" {
  type        = string
  description = "The username of the Postgres database."
  default     = "user"
}

variable "database_password" {
  type        = string
  description = "The password of the Postgres database."
  sensitive   = true
}

variable "docker_image" {
  type        = string
  description = "The docker image to deploy to Cloud Run."
  default     = "mageai/mageai:latest"
}

variable "domain" {
  description = "Domain name to run the load balancer on. Used if `ssl` is `true`."
  type        = string
  default     = ""
}

variable "ssl" {
  description = "Run load balancer on HTTPS and provision managed certificate with provided `domain`."
  type        = bool
  default     = false
}


# BIGQUERY DWH
variable "bq_dataset_name" {
  description = "My BigQuery Dataset Name"
  default     = "indego_tripdata"
}

# CLOUD STORAGE
variable "gcs_bucket_name" {
  description = "My Storage Bucket Name"
  default     = "indego_815299289556"
}

variable "gcs_storage_class" {
  description = "Bucket Storage Class"
  default     = "STANDARD"
}


# DATAPROC CLUSTER
variable "cluster_name" {
  description = "name for dataproc cluster"
  default     = "indego-cluster"
}
# main.tf

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "5.6.0"
    }
  }
}

provider "google" {
  credentials = file(var.credentials)
  project     = var.project_id
  region      = var.region
}


# ENABLE APIS

# Enable IAM API
resource "google_project_service" "iam" {
  service            = "iam.googleapis.com"
  disable_on_destroy = false
}

# Enable Artifact Registry API
resource "google_project_service" "artifactregistry" {
  service            = "artifactregistry.googleapis.com"
  disable_on_destroy = false
}

# Enable Cloud Run API
resource "google_project_service" "cloudrun" {
  service            = "run.googleapis.com"
  disable_on_destroy = false
}

# Enable Cloud Resource Manager API
resource "google_project_service" "resourcemanager" {
  service            = "cloudresourcemanager.googleapis.com"
  disable_on_destroy = false
}

# Enable VCP Access API
resource "google_project_service" "vpcaccess" {
  service            = "vpcaccess.googleapis.com"
  disable_on_destroy = false
}

# Enable Secret Manager API
resource "google_project_service" "secretmanager" {
  service            = "secretmanager.googleapis.com"
  disable_on_destroy = false
}

# Enable Cloud SQL Admin API
resource "google_project_service" "sqladmin" {
  service            = "sqladmin.googleapis.com"
  disable_on_destroy = false
}


# CREATE SERVICE ACCOUNTS & ASSIGN IAM ROLES

resource "google_service_account" "cloud_run_sa" {
  account_id   = "cloud-run-sa"
  display_name = "Cloud Run Service Account"
}

resource "google_service_account" "dataproc_sa" {
  account_id   = "dataproc-sa"
  display_name = "Dataproc Service Account"
}

resource "google_project_iam_member" "dataproc_worker" {
  project = var.project_id
  role    = "roles/dataproc.worker"
  member  = "serviceAccount:${google_service_account.dataproc_sa.email}"
}

# Permissions for Cloud Run Service Account
resource "google_project_iam_member" "cloud_run_gcs_creator" {
  project = var.project_id
  role    = "roles/storage.objectCreator"
  member  = "serviceAccount:${google_service_account.cloud_run_sa.email}"
}
resource "google_project_iam_member" "cloud_sql_admin" {
  project = var.project_id
  role    = "roles/cloudsql.admin"
  member  = "serviceAccount:${google_service_account.cloud_run_sa.email}"
}

resource "google_project_iam_member" "cloud_run_dataproc_editor" {
  project = var.project_id
  role    = "roles/dataproc.editor"
  member  = "serviceAccount:${google_service_account.cloud_run_sa.email}"
}

# Permissions for Dataproc Service Account
resource "google_project_iam_member" "dataproc_gcs_user" {
  project = var.project_id
  role    = "roles/storage.objectUser"
  member  = "serviceAccount:${google_service_account.dataproc_sa.email}"
}

resource "google_project_iam_member" "dataproc_bigquery_data_editor" {
  project = var.project_id
  role    = "roles/bigquery.dataEditor"
  member  = "serviceAccount:${google_service_account.dataproc_sa.email}"
}



# OUTPUT SERVICE ACCOUNT EMAILS
output "cloud_run_service_account_email" {
  value = google_service_account.cloud_run_sa.email
}

output "dataproc_service_account_email" {
  value = google_service_account.dataproc_sa.email
}

output "cloud_sql_connection_name" {
  value = google_sql_database_instance.instance.connection_name
}


# CREATE CLOUD RUN SERVICE
resource "google_cloud_run_service" "run_service" {
  name     = var.app_name
  location = var.region

  template {
    spec {
      service_account_name = google_service_account.cloud_run_sa.email
      containers {
        image = var.docker_image
        ports {
          container_port = 6789
        }
        resources {
          limits = {
            cpu    = var.container_cpu
            memory = var.container_memory
          }
        }
        env {
          name  = "FILESTORE_IP_ADDRESS"
          value = google_filestore_instance.instance.networks[0].ip_addresses[0]
        }
        env {
          name  = "FILE_SHARE_NAME"
          value = "share1"
        }
        env {
          name  = "GCP_PROJECT_ID"
          value = var.project_id
        }
        env {
          name  = "GCP_REGION"
          value = var.region
        }
        env {
          name  = "GCP_SERVICE_NAME"
          value = var.app_name
        }
        env {
          name  = "MAGE_DATABASE_CONNECTION_URL"
          value = "postgresql://${var.database_user}:${var.database_password}@/${var.app_name}-db?host=/cloudsql/${google_sql_database_instance.instance.connection_name}"
          # value = "postgresql+psycopg2://${var.database_user}:${var.database_password}@host:5432/${google_sql_database_instance.instance.name}"
          # value = "postgresql://${var.database_user}:${var.database_password}@/${var.app_name}-db?host=/cloudsql/${google_sql_database_instance.instance.connection_name}"
          # value = "postgresql://${var.database_user}:${var.database_password}@/cloudsql/${var.project_id}:${var.region}:${google_sql_database_instance.instance.name}/${google_sql_database.database.name}"
        }
        env {
          name  = "ULIMIT_NO_FILE"
          value = 16384
        }
        # volume_mounts {
        #   mount_path = "/secrets/bigquery"
        #   name       = "secret-bigquery-key"
        # }
      }
      # volumes {
      #   name = "secret-bigquery-key"
      #   secret {
      #     secret_name  = "bigquery_key"
      #     items {
      #       key  = "latest"
      #       path = "bigquery_key"
      #     }
      #   }
      # }
    }

    metadata {
      annotations = {
        "autoscaling.knative.dev/minScale"         = "1"
        "run.googleapis.com/cloudsql-instances"    = google_sql_database_instance.instance.connection_name
        "run.googleapis.com/cpu-throttling"        = false
        "run.googleapis.com/execution-environment" = "gen2"
        "run.googleapis.com/vpc-access-connector"  = google_vpc_access_connector.connector.id
        "run.googleapis.com/vpc-access-egress"     = "private-ranges-only"
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }

  autogenerate_revision_name = true

  # Waits for the Cloud Run API to be enabled
  depends_on = [google_project_service.cloudrun]
}


# Allow unauthenticated users to invoke the service
resource "google_cloud_run_service_iam_member" "run_all_users" {
  service  = google_cloud_run_service.run_service.name
  location = google_cloud_run_service.run_service.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}



# CREATE CLOUD STORAGE BUCKET
resource "google_storage_bucket" "indego_storage" {
  name          = var.gcs_bucket_name
  location      = var.location
  force_destroy = true

  lifecycle_rule {
    condition {
      age = 1
    }
    action {
      type = "AbortIncompleteMultipartUpload"
    }
  }
}


# CREATE BIGQUERY DATASET
resource "google_bigquery_dataset" "bq-dataset" {
  dataset_id = var.bq_dataset_name
  location   = var.location
}


# CREATE SIMPLE DATAPROC CLUSTER
resource "google_dataproc_cluster" "indego-cluster" {
  name                          = var.cluster_name
  region                        = var.region
  graceful_decommission_timeout = "120s"

  cluster_config {
    staging_bucket = google_storage_bucket.indego_storage.name
    temp_bucket    = google_storage_bucket.indego_storage.name

    endpoint_config {
      enable_http_port_access = true
    }

    master_config {
      num_instances = 1
      machine_type  = "n1-standard-4"
      disk_config {
        boot_disk_type    = "pd-ssd"
        boot_disk_size_gb = 50
      }
    }

    worker_config {
      num_instances = 2
      machine_type  = "n1-standard-4"
      disk_config {
        boot_disk_size_gb = 50
        num_local_ssds    = 1
      }
    }

    gce_cluster_config {
      # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
      service_account        = google_service_account.dataproc_sa.email
      service_account_scopes = ["cloud-platform"]
    }
  }
  depends_on = [google_project_iam_member.dataproc_worker]
}
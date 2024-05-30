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
  project     = var.project
  region      = var.region
}


# CREATE CLOUD STORAGE BUCKET
resource "google_storage_bucket" "septa_storage" {
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
resource "google_bigquery_dataset" "septa_data" {
  dataset_id = var.bq_dataset_name
  location   = var.location
}

# CREATE SIMPLE DATAPROC CLUSTER
resource "google_dataproc_cluster" "septa-cluster" {
  name   = var.cluster_name
  region = var.region

  cluster_config {
    staging_bucket = var.gcs_bucket_name

    endpoint_config {
      enable_http_port_access = true
    }

    gce_cluster_config {
      service_account        = var.zoomcamp_service_account_email
      service_account_scopes = ["cloud-platform"]
    }
  }
}



# COMPUTE INSTANCE

# static IP address
resource "google_compute_address" "default" {
  name = "septa-vm-ip"
}

# actual compute engine VM
resource "google_compute_instance" "septa_pipeline_vm" {
  name         = "septa-pipeline-vm"
  machine_type = "e2-standard-4"
  zone         = "us-central1-a"

  boot_disk {
    auto_delete = false
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2004-lts"
    }
  }

  network_interface {
    network = "default"
    access_config {
      nat_ip = google_compute_address.default.address
    }
  }

  service_account {
    email  = var.zoomcamp_service_account_email
    scopes = ["cloud-platform"]
  }

  metadata = {
    ssh-keys = "${var.ssh_user}:${file(var.public_ssh_key_path)}"
  }

  metadata_startup_script = file(var.startup_script)
}
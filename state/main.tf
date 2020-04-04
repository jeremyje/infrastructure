# Copyright 2020 Codecahedron Authors
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# https://registry.terraform.io/providers/hashicorp/google/3.13.0
provider "google" {
  version = ">=3.13.0"
}

provider "google-beta" {
  version = ">=3.13.0"
}

data "google_project" "project" {
  project_id = var.gcp_project_id
}

# Ensure that GCS is enabled.
resource "google_project_service" "gcp_apis" {
  for_each = toset([
    "storage-api.googleapis.com",
    "storage-component.googleapis.com",
  ])

  service = each.key

  project            = data.google_project.project.project_id
  disable_on_destroy = false
}

# GCS Bucket for storing Terraform State information.
resource "google_storage_bucket" "terraform-state" {
  provider           = google-beta
  name               = "codecahedron-terraform-shippable"
  project            = data.google_project.project.project_id
  location           = "US"
  force_destroy      = false
  bucket_policy_only = true
  storage_class      = "STANDARD"


  labels = {
    environment = "production"
  }

  versioning {
    enabled = true
  }
}

data "google_iam_policy" "terraform-state-policy" {
  binding {
    role = "roles/storage.admin"
    members = [
      "group:codecahedron-admins@googlegroups.com",
      "serviceAccount:continuous-integration@gcp-codecahedron.iam.gserviceaccount.com",
    ]
  }
}

resource "google_storage_bucket_iam_policy" "editor" {
  bucket      = google_storage_bucket.terraform-state.name
  policy_data = data.google_iam_policy.terraform-state-policy.policy_data
}

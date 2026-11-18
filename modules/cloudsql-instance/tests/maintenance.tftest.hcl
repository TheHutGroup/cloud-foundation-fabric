# Copyright 2026 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

mock_provider "google" {}
mock_provider "google-beta" {
  mock_resource "google_sql_database_instance" {
    defaults = {
      maintenance_version            = "POSTGRES_16_13.R20260501.01_00"
      available_maintenance_versions = ["POSTGRES_16_14.R20260712.01_06"]
    }
  }
}
mock_provider "random" {}

variables {
  project_id       = "test-project"
  name             = "test-db"
  region           = "europe-west2"
  database_version = "POSTGRES_16"
  tier             = "db-custom-2-7680"
  network_config   = { connectivity = { public_ipv4 = true } }
}

run "explicit_primary_target" {
  command = plan
  variables {
    maintenance_version = "POSTGRES_16_14.R20260712.01_06"
  }
  assert {
    condition     = google_sql_database_instance.primary.maintenance_version == "POSTGRES_16_14.R20260712.01_06"
    error_message = "The explicit maintenance target must reach the primary."
  }
  assert {
    condition     = output.maintenance_version == "POSTGRES_16_14.R20260712.01_06"
    error_message = "The primary maintenance version must be exposed."
  }
}

run "omitted_target" {
  command = plan
  assert {
    condition     = var.maintenance_version == null
    error_message = "Existing callers must not acquire an explicit target."
  }
}

run "replicas_keep_provider_managed_version" {
  command = apply
  variables {
    maintenance_version = "POSTGRES_16_14.R20260712.01_06"
    replicas = {
      reader = { region = "europe-west2" }
    }
  }
  assert {
    condition     = google_sql_database_instance.replicas["reader"].maintenance_version == "POSTGRES_16_13.R20260501.01_00"
    error_message = "The primary target must not be assigned independently to replicas."
  }
  assert {
    condition     = output.available_maintenance_versions == tolist(["POSTGRES_16_14.R20260712.01_06"])
    error_message = "Available versions must come from the primary."
  }
}

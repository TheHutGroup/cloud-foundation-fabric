/**
 * Copyright 2025 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

locals {
  cloud_config = templatefile("cloud-config.yaml", merge(var.agent_config, {
    image      = "${module.registry.url}/${var.agent_config.image}"
    location   = var.location
    name       = var.name
    project_id = var.project_id
  }))
}

module "registry" {
  source     = "../../../modules/artifact-registry"
  project_id = var.project_id
  location   = var.location
  name       = "${var.name}-docker"
  format = {
    docker = {
      standard = {}
    }
  }
}

module "secret" {
  source     = "../../../modules/secret-manager"
  project_id = var.project_id
  secrets = {
    (var.name) = {
      iam = {
        "roles/secretmanager.secretAccessor" = [
          "serviceAccount:${var.instance_config.service_account}"
        ]
      }
      versions = {
        "v-${var.agent_config.azp.token.version}" = {
          data = try(file(var.agent_config.azp.token.file), null)
          data_config = {
            write_only_version = var.agent_config.azp.token.version
          }
        }
      }
    }
  }
}

module "agent" {
  source        = "../../../modules/compute-vm"
  count         = var.instance_config == null ? 0 : 1
  project_id    = var.project_id
  zone          = "${var.location}-${var.instance_config.zone}"
  name          = "${var.name}-agent"
  instance_type = "e2-micro"
  boot_disk = {
    auto_delete = false
    initialize_params = {
      image = "projects/cos-cloud/global/images/family/cos-117-lts"
      size  = 10
    }
  }
  network_interfaces = [{
    network    = var.instance_config.vpc_config.network
    subnetwork = var.instance_config.vpc_config.subnetwork
  }]
  metadata = {
    user-data = local.cloud_config
  }
  service_account = {
    email = var.instance_config.service_account
  }
  depends_on = [module.secret]
}

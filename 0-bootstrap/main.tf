provider "google" {
  region = var.region
}

resource "random_id" "project_id" {
  byte_length = 4
}

resource "google_project" "project" {
  org_id              = var.parent.parent_type == "organizations" ? var.parent.parent_id : null
  folder_id           = var.parent.parent_type == "folders" ? var.parent.parent_id : null
  project_id          = "${var.project_name}-${random_id.project_id.hex}"
  name                = "${var.project_name}-${random_id.project_id.hex}"
  billing_account     = var.billing_account
  auto_create_network = false
}

resource "google_project_service" "project_services" {
  for_each = toset([
    "cloudbuild.googleapis.com",
    "artifactregistry.googleapis.com",
    "run.googleapis.com",
    "secretmanager.googleapis.com"
  ])
  project = google_project.project.project_id
  service = each.value
}

resource "google_artifact_registry_repository" "my-repo" {
  repository_id = "sg-repository"

  project       = google_project.project.project_id
  location      = var.region
  description   = "SG docker repository"
  format        = "DOCKER"
}

resource "google_secret_manager_secret" "github_token_secret" {
  secret_id = "sg-github-secrtet"
  replication {
    auto {}
  }
  project = google_project.project.project_id

}

resource "google_secret_manager_secret_version" "github_secret_version" {
  secret      = google_secret_manager_secret.github_token_secret.id
  secret_data = var.github_secret
}


data "google_iam_policy" "p4sa_secretAccessor" {
  binding {
    role = "roles/secretmanager.secretAccessor"
    members = ["serviceAccount:service-${google_project.project.number}@gcp-sa-cloudbuild.iam.gserviceaccount.com"]
  }
}

resource "google_secret_manager_secret_iam_policy" "policy" {
  secret_id   = google_secret_manager_secret.github_token_secret.secret_id
  policy_data = data.google_iam_policy.p4sa_secretAccessor.policy_data
  project     = google_project.project.project_id

}

resource "google_project_iam_member" "cloud_run_admin" {
  project     = google_project.project.project_id
  role   = "roles/run.admin"
  member = "serviceAccount:${google_project.project.number}@cloudbuild.gserviceaccount.com"
}

resource "google_project_iam_member" "sa_user" {
  project     = google_project.project.project_id
  role   = "roles/iam.serviceAccountUser"
  member = "serviceAccount:${google_project.project.number}@cloudbuild.gserviceaccount.com"
}

resource "google_cloudbuildv2_connection" "my_connection" {
  project  = google_project.project.project_id
  location = var.region
  name     = "sg-connection"

  github_config {
    app_installation_id = var.app_installation_id
    authorizer_credential {
      oauth_token_secret_version = google_secret_manager_secret_version.github_secret_version.id
    }
  }
}

resource "google_cloudbuildv2_repository" "my_repository" {
  name              = "sg-repo"
  parent_connection = google_cloudbuildv2_connection.my_connection.id
  remote_uri        = var.github_repo_url
  project           = google_project.project.project_id
}

resource "google_cloudbuild_trigger" "repo_trigger" {
  project  = google_project.project.project_id
  location = var.region

  repository_event_config {
    repository = google_cloudbuildv2_repository.my_repository.id
    push {
    #  branch = "feature-.*"
       branch = "master"
    }
  }

  filename = "cloudbuild.yaml"
}

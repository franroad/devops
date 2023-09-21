provider "google" {
  project = "gke-poc-397512"
}

locals {
  emails = {
    1 = "arcadi.dolcet@sngular.com", 
    2 = "josep.rego@sngular.com",
    3 = "francisco.bernal@sngular.com",
  }
}

resource "google_monitoring_notification_channel" "basic" {
  for_each = { for i, val in local.emails : i => val }
  display_name = "Test Notification - ${each.key}"
  type         = "email"
  labels = {
    email_address = each.value
  }
  force_delete = false
}

resource "google_monitoring_alert_policy" "alert_policy" {
  display_name = "GKE Policy"
  combiner     = "OR"
  conditions {
    display_name = "test condition"
    condition_threshold {
      filter     = "metric.type=\"kubernetes.io/container/cpu/core_usage_time\" AND resource.type=\"k8s_container\""
      duration   = "60s"
      comparison = "COMPARISON_GT"
      threshold_value = 0.4
      trigger {
          count = 1
        }
      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_RATE"
      }
    }
  }

 notification_channels = values(google_monitoring_notification_channel.basic)[*].id // name of the resource (basic)

  documentation {
    content = "blablabl"
  }
}

resource "google_monitoring_dashboard" "dashboard" {
  dashboard_json = file("/home/arcadi_dolcet_admin/dashboard.json")
}

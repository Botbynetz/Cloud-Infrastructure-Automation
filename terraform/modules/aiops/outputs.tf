# AIOps Module Outputs

output "ml_data_bucket_id" {
  description = "S3 bucket ID for ML data"
  value       = aws_s3_bucket.ml_data.id
}

output "metrics_stream_name" {
  description = "Kinesis stream name for metrics"
  value       = aws_kinesis_stream.metrics_stream.name
}

output "metrics_collector_lambda_arn" {
  description = "Metrics collector Lambda ARN"
  value       = aws_lambda_function.metrics_collector.arn
}

output "anomaly_detector_lambda_arn" {
  description = "Anomaly detector Lambda ARN"
  value       = aws_lambda_function.anomaly_detector.arn
}

output "predictive_scaler_lambda_arn" {
  description = "Predictive scaler Lambda ARN"
  value       = aws_lambda_function.predictive_scaler.arn
}

output "aiops_alerts_topic_arn" {
  description = "SNS topic ARN for AIOps alerts"
  value       = aws_sns_topic.aiops_alerts.arn
}

output "aiops_dashboard_name" {
  description = "CloudWatch dashboard name"
  value       = aws_cloudwatch_dashboard.aiops.dashboard_name
}

output "aiops_summary" {
  description = "AIOps configuration summary"
  value = {
    project                      = "${var.project_name}-${var.environment}"
    ml_data_bucket               = aws_s3_bucket.ml_data.id
    metrics_stream               = aws_kinesis_stream.metrics_stream.name
    ml_predictions_enabled       = var.enable_ml_predictions
    predictive_scaling_enabled   = var.enable_predictive_scaling
    auto_remediation_enabled     = var.enable_auto_remediation
    anomaly_threshold            = var.anomaly_detection_threshold
    prediction_window_hours      = var.prediction_window_hours
    metrics_collection_frequency = "Every 5 minutes"
    predictive_scaling_frequency = "Every 15 minutes"
    estimated_monthly_cost       = "$150-300"
  }
}

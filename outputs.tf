output "elasticsearch_endpoint" {
  description = "Elasticsearch public endpoint"
  value       = "https://elasticsearch.${var.domain}"
}

output "kibana_endpoint" {
  description = "Kibana public endpoint"
  value       = "https://kibana.${var.domain}"
}

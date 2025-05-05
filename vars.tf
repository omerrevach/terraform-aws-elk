variable "region" {
  description = "AWS region"
  type        = string
  default = null
}

variable "acm_cert_id" {
  description = "The ACM certificate ID to use for ALB HTTPS"
  type        = string
  default = null
}

variable "domain" {
  description = "Base domain name (e.g., stockpnl.com)"
  type        = string
  default = null
}

variable "elasticsearch_version" {
  description = "Version of Elasticsearch to deploy"
  type        = string
  default     = "8.12.2"
}

variable "kibana_version" {
  description = "Version of Kibana to deploy"
  type        = string
  default     = "8.12.2"
}

variable "elasticsearch_storage_size" {
  description = "Elasticsearch data volume size (e.g., 20Gi)"
  type        = string
  default     = "30Gi"
}

variable "elasticsearch_node_count" {
  description = "Number of Elasticsearch nodes"
  type        = number
  default     = 1
}

variable "elasticsearch_storage_class" {
  description = "Storage class name for Elasticsearch PVC"
  type        = string
  default     = "gp3"
}

variable "alb_group_name" {
  description = "ALB ingress group name (to combine multiple ingresses under the same ALB)"
  type        = string
  default     = "elk-stack"
}

variable "extra_alb_annotations_elasticsearch" {
  description = "Extra annotations for the Elasticsearch ingress (map)"
  type        = map(string)
  default     = {}
}

variable "extra_alb_annotations_kibana" {
  description = "Extra annotations for the Kibana ingress (map)"
  type        = map(string)
  default     = {}
}

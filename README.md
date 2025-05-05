# Terraform AWS ELK Stack Module

This Terraform module deploys the Elastic Stack (Elasticsearch and Kibana) on an AWS EKS cluster using the Elastic Cloud on Kubernetes (ECK) operator.

## Features

- Deploys Elasticsearch and Kibana on Kubernetes
- Configurable node count and storage
- Public access through AWS ALB with TLS
- Custom domain names
- Configurable Elasticsearch and Kibana versions

## Prerequisites

- An existing EKS cluster
- Terraform >= 1.0.0
- AWS Load Balancer Controller installed on your cluster
- A domain name with a valid ACM certificate

## Required Providers

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.0.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.14.0"
    }
    time = {
      source  = "hashicorp/time"
      version = ">= 0.7.0"
    }
  }
}
```

## Usage

```hcl
module "elk" {
  source = "omerrevach/elk/aws"
  version = "1.0.0"
  
  region           = "us-west-2"
  domain           = "example.com"
  acm_cert_id      = "12345678-1234-1234-1234-123456789012"
  
  # Optional configurations
  elasticsearch_version     = "8.12.2"
  kibana_version            = "8.12.2"
  elasticsearch_node_count  = 3
  elasticsearch_storage_size = "50Gi"
  elasticsearch_storage_class = "gp3"
  
  alb_group_name = "my-elk-stack"
  
  # Add custom ALB annotations if needed
  extra_alb_annotations_elasticsearch = {
    "alb.ingress.kubernetes.io/auth-type" = "cognito"
  }
  
  extra_alb_annotations_kibana = {
    "alb.ingress.kubernetes.io/auth-type" = "cognito"
  }
}
```

## Variables

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| region | AWS region | `string` | n/a | yes |
| acm_cert_id | The ACM certificate ID to use for ALB HTTPS | `string` | n/a | yes |
| domain | Base domain name (e.g., example.com) | `string` | n/a | yes |
| elasticsearch_version | Version of Elasticsearch to deploy | `string` | `"8.12.2"` | no |
| kibana_version | Version of Kibana to deploy | `string` | `"8.12.2"` | no |
| elasticsearch_storage_size | Elasticsearch data volume size | `string` | `"30Gi"` | no |
| elasticsearch_node_count | Number of Elasticsearch nodes | `number` | `1` | no |
| elasticsearch_storage_class | Storage class name for Elasticsearch PVC | `string` | `"gp3"` | no |
| alb_group_name | ALB ingress group name | `string` | `"elk-stack"` | no |
| extra_alb_annotations_elasticsearch | Extra annotations for Elasticsearch ingress | `map(string)` | `{}` | no |
| extra_alb_annotations_kibana | Extra annotations for Kibana ingress | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| elasticsearch_endpoint | Elasticsearch public endpoint |
| kibana_endpoint | Kibana public endpoint |

## Architecture

This module:

1. Deploys the ECK operator using Helm
2. Creates Elasticsearch cluster with configurable node count and storage
3. Deploys Kibana connected to the Elasticsearch cluster
4. Creates ingress resources for both Elasticsearch and Kibana with ALB integration

## Accessing Elasticsearch and Kibana

After successful deployment, you can access:

- Elasticsearch at: `https://elasticsearch.your-domain.com`
- Kibana at: `https://kibana.your-domain.com`

Default credentials can be found in the Kubernetes secret named `elasticsearch-es-elastic-user` in the `elastic-system` namespace:

```bash
kubectl get secret elasticsearch-es-elastic-user -n elastic-system -o jsonpath='{.data.elastic}' | base64 --decode
```

## DNS Configuration

You need to create DNS records for:
- `elasticsearch.your-domain.com` pointing to the ALB
- `kibana.your-domain.com` pointing to the ALB

## Security Considerations

- This module disables TLS for Elasticsearch and Kibana internally but uses HTTPS for external access
- For production use, consider enabling internal TLS and adding authentication
- Review the ALB security groups and network policies

## License

MIT
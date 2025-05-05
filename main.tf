data "aws_caller_identity" "current" {}

resource "helm_release" "eck_operator" {
  name       = "eck-operator"
  namespace  = "elastic-system"
  repository = "https://helm.elastic.co"
  chart      = "eck-operator"

  create_namespace = true

  set {
    name  = "installCRDs"
    value = "true"
  }
}

resource "time_sleep" "wait_for_addons" {
  depends_on = [helm_release.eck_operator]
  create_duration = "120s"
}

resource "kubectl_manifest" "elasticsearch" {
  yaml_body = <<-YAML
apiVersion: elasticsearch.k8s.elastic.co/v1
kind: Elasticsearch
metadata:
  name: elasticsearch
  namespace: elastic-system
spec:
  version: ${var.elasticsearch_version}
  http:
    tls:
      selfSignedCertificate:
        disabled: true
  nodeSets:
    - name: default
      count: ${var.elasticsearch_node_count}
      config:
        node.store.allow_mmap: false
      volumeClaimTemplates:
        - metadata:
            name: elasticsearch-data
          spec:
            accessModes: [ "ReadWriteOnce" ]
            resources:
              requests:
                storage: ${var.elasticsearch_storage_size}
            storageClassName: ${var.elasticsearch_storage_class}
YAML

  depends_on = [time_sleep.wait_for_addons]
}

resource "kubectl_manifest" "kibana" {
  yaml_body = <<-YAML
apiVersion: kibana.k8s.elastic.co/v1
kind: Kibana
metadata:
  name: kibana
  namespace: elastic-system
spec:
  version: ${var.kibana_version}
  count: 1
  elasticsearchRef:
    name: elasticsearch
  http:
    tls:
      selfSignedCertificate:
        disabled: true
YAML

  depends_on = [kubectl_manifest.elasticsearch]
}

resource "kubectl_manifest" "elasticsearch_ingress" {
  yaml_body = <<-YAML
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: elasticsearch-ingress
  namespace: elastic-system
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/group.name: ${var.alb_group_name}
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTPS":443}]'
    alb.ingress.kubernetes.io/certificate-arn: arn:aws:acm:${var.region}:${data.aws_caller_identity.current.account_id}:certificate/${var.acm_cert_id}
    alb.ingress.kubernetes.io/healthcheck-path: "/_cluster/health"
    alb.ingress.kubernetes.io/backend-protocol: HTTP
    alb.ingress.kubernetes.io/success-codes: "200-399"
${join("\n", [for key, value in var.extra_alb_annotations_elasticsearch : "    ${key}: ${value}"])}
spec:
  rules:
    - host: elasticsearch.${var.domain}
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: elasticsearch-es-http
                port:
                  number: 9200
YAML

  depends_on = [kubectl_manifest.elasticsearch]
}

resource "kubectl_manifest" "kibana_ingress" {
  yaml_body = <<-YAML
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: kibana-ingress
  namespace: elastic-system
  annotations:
    kubernetes.io/ingress.class: alb
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/group.name: ${var.alb_group_name}
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTPS":443}]'
    alb.ingress.kubernetes.io/certificate-arn: arn:aws:acm:${var.region}:${data.aws_caller_identity.current.account_id}:certificate/${var.acm_cert_id}
    alb.ingress.kubernetes.io/healthcheck-path: "/api/status"
    alb.ingress.kubernetes.io/backend-protocol: HTTP
    alb.ingress.kubernetes.io/success-codes: "200-399"
${join("\n", [for key, value in var.extra_alb_annotations_kibana : "    ${key}: ${value}"])}
spec:
  rules:
    - host: kibana.${var.domain}
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: kibana-kb-http
                port:
                  number: 5601
YAML

  depends_on = [kubectl_manifest.kibana]
}

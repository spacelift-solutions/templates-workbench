apiVersion: v1
kind: Namespace
metadata:
  name: ${NAMESPACE}
  labels:
    environment: ${ENVIRONMENT}
    managed-by: spacelift

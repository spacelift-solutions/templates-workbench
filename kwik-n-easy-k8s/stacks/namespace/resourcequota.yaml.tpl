apiVersion: v1
kind: ResourceQuota
metadata:
  name: ${NAMESPACE}-quota
  namespace: ${NAMESPACE}
spec:
  hard:
    requests.cpu: "${CPU_LIMIT}"
    requests.memory: ${MEMORY_LIMIT}
    limits.cpu: "${CPU_LIMIT}"
    limits.memory: ${MEMORY_LIMIT}
    pods: "20"

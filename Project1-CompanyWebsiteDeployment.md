# Project 1: Company Website Deployment

## Business Problem
TechStart, a new software startup, needs to deploy their company website. The website must be:
- Highly available (no single point of failure)
- Easy to update with new versions
- Able to handle traffic spikes during marketing campaigns

## Solution
Deploy a scalable web application using Kubernetes Pods and Deployments with multiple replicas. This ensures the website remains available even if individual instances fail.

## Expected Outcomes
1. A stable website accessible through a consistent endpoint
2. Ability to update the website without downtime
3. Automatic recovery if any instance crashes
4. Ability to scale up during peak times

## Kubernetes Concepts Covered
- **Pods**: The basic unit of deployment in Kubernetes
- **ReplicaSets**: Ensures a specified number of pod replicas are running
- **Deployments**: Manages ReplicaSets and provides declarative updates

## Project Implementation

### Step 1: Create a Namespace
First, let's create a dedicated namespace for our website:

```yaml
# namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: techstart-website
```

Apply with:
```bash
kubectl apply -f namespace.yaml
```

**Explanation**: Namespaces provide isolation for resources in a cluster. They help organize applications and provide a scope for names.

### Step 2: Deploy the Website

```yaml
# website-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: company-website
  namespace: techstart-website
  labels:
    app: company-website
spec:
  replicas: 3  # Run 3 instances for high availability
  selector:
    matchLabels:
      app: company-website
  template:
    metadata:
      labels:
        app: company-website
    spec:
      containers:
      - name: website
        image: nginx:1.21  # Using Nginx to serve static content
        ports:
        - containerPort: 80
        resources:
          requests:
            memory: "64Mi"
            cpu: "100m"
          limits:
            memory: "128Mi"
            cpu: "200m"
        readinessProbe:  # Ensure the container is ready to receive traffic
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 10
        livenessProbe:  # Restart if the container becomes unhealthy
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 15
          periodSeconds: 20
```

Apply with:
```bash
kubectl apply -f website-deployment.yaml
```

**Key Concepts Explained**:
- **Kind: Deployment**: A higher-level resource that manages ReplicaSets to provide declarative updates.
- **replicas: 3**: Ensures 3 identical pods are always running.
- **selector**: Determines which pods are managed by this deployment.
- **template**: Defines the pod specification to be created.
- **resources**: Specifies CPU and memory requirements.
- **readinessProbe**: Determines when the pod is ready to serve traffic.
- **livenessProbe**: Determines if the pod should be restarted due to failure.

### Step 3: Expose the Website with a Service

```yaml
# website-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: company-website
  namespace: techstart-website
spec:
  type: NodePort  # Makes the service accessible outside the cluster
  selector:
    app: company-website  # Selects pods with this label
  ports:
  - port: 80  # Service port
    targetPort: 80  # Container port
    nodePort: 30080  # Port on the node
```

Apply with:
```bash
kubectl apply -f website-service.yaml
```

**Explanation**: Services provide a stable endpoint to access pods. The NodePort type exposes the service on each node's IP at a static port (30080).

## Verifying the Deployment

Check that everything is running:
```bash
kubectl get all -n techstart-website
```

View logs from pods:
```bash
kubectl logs -n techstart-website deployment/company-website
```

## Troubleshooting Guide

### Problem 1: Pods Not Starting
**Symptoms**: Pods remain in "Pending" state.
**Potential Causes**:
- Insufficient cluster resources
- Image pull errors

**Diagnosis Commands**:
```bash
kubectl describe pod -n techstart-website [pod-name]
```

**Solution**: Look for events in the describe output indicating resource constraints or image issues. You might need to adjust resource requests or fix the image reference.

### Problem 2: Website Not Accessible
**Symptoms**: Cannot access the website through NodePort.
**Potential Causes**:
- Service not properly configured
- Pod readiness issues

**Diagnosis Commands**:
```bash
kubectl get endpoints -n techstart-website company-website
kubectl describe service -n techstart-website company-website
```

**Solution**: Ensure endpoints exist (which means pods are ready and matched by the service selector). If no endpoints, check pod readiness and labels.

### Problem 3: Deployment Updates Failing
**Symptoms**: New version not being deployed, or rolling out very slowly.
**Potential Causes**:
- Readiness probe failures
- Resource constraints

**Diagnosis Commands**:
```bash
kubectl rollout status -n techstart-website deployment/company-website
kubectl describe deployment -n techstart-website company-website
```

**Solution**: Check the rollout status and deployment events. You may need to adjust readiness probe parameters or resource allocations.

## Advanced Challenges

1. **Update the Deployment**: Change the Nginx version to 1.22 and observe the rolling update process.
2. **Scale the Deployment**: Increase the replicas to 5 during a simulated traffic spike.
3. **Add Custom Content**: Create a ConfigMap with HTML content and mount it into the pods.

## Knowledge Check
1. What happens if you delete one pod? Will the service be affected?
2. How does Kubernetes ensure high availability with Deployments?
3. What's the difference between a readinessProbe and a livenessProbe?
4. Why use a Service instead of directly accessing pods?

## Next Steps
In Project 2, we'll explore multi-service applications and different Service types for more complex scenarios.
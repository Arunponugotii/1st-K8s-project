# ShopFast E-commerce Microservices Project

## Business Problem

ShopFast, an e-commerce company, needs to deploy their application consisting of multiple components that must be independently scalable and manageable. The application must handle product browsing, user authentication, personalized recommendations, and allow for future growth with minimal downtime.

Traditional monolithic architectures struggle with:
- Independent scaling of high-traffic components
- Fault isolation (one component failure bringing down the entire system)
- Technology flexibility (using the right technology for each component)
- Continuous deployment without full system downtime

## Solution: Microservices Architecture in Kubernetes

This project implements a production-grade microservices architecture using Google's Online Boutique (Microservices Demo) components, deployed on Kubernetes with proper service discovery, networking, and resource management.

The implementation uses real, production-ready microservices that communicate with each other to create a functioning e-commerce platform.

## Architecture Overview

![Architecture Diagram](https://github.com/GoogleCloudPlatform/microservices-demo/raw/main/docs/img/architecture-diagram.png)

We're implementing four core services from the Online Boutique project:

1. **Frontend Service** - Customer-facing web UI 
2. **Product Catalog Service** - Product information database
3. **Authentication/Checkout Service** - User authentication and order processing
4. **Recommendation Service** - AI-powered product recommendations

## Detailed Component Analysis

### 1. Frontend Service

**Business Purpose:** Serves as the customer-facing interface for browsing products, adding items to cart, and completing purchases.

**Technical Details:**
```yaml
# Key fields from frontend-deployment.yaml
containers:
- name: web-ui
  image: gcr.io/google-samples/microservices-demo/frontend:v0.8.0
  ports:
  - containerPort: 8080    # Frontend listens on port 8080 internally
  env:
  - name: PORT
    value: "8080"
  - name: PRODUCT_CATALOG_SERVICE_ADDR
    value: "product-catalog:80"    # Service discovery via DNS
  resources:
    requests:      # Minimum resources required
      memory: "128Mi"
      cpu: "100m"
    limits:        # Maximum resources allowed
      memory: "256Mi"
      cpu: "200m"
```

**Service Definition:**
```yaml
# frontend-service.yaml
type: LoadBalancer    # Exposes service externally with cloud provider load balancer
selector:
  app: frontend       # Routes traffic to pods with this label
ports:
- port: 80            # The port exposed externally
  targetPort: 8080    # The container port to route traffic to
```

**Why these resource settings?**
- The frontend needs moderate CPU (100m = 0.1 CPU core) as it handles HTTP requests, template rendering
- Memory allocation (128Mi) is sufficient for a web service with moderate traffic
- Exposed externally via LoadBalancer to allow customer access

### 2. Product Catalog Service

**Business Purpose:** Stores and serves product information including prices, availability, and descriptions.

**Technical Details:**
```yaml
# Key fields from catalog-deployment.yaml
containers:
- name: catalog
  image: gcr.io/google-samples/microservices-demo/productcatalogservice:v0.8.0
  ports:
  - containerPort: 3550    # Internal port product catalog listens on
  env:
  - name: PORT
    value: "3550"
  resources:
    requests:
      memory: "128Mi"
      cpu: "100m"
    limits:
      memory: "256Mi"
      cpu: "200m"
```

**Service Definition:**
```yaml
# catalog-service.yaml
type: ClusterIP       # Only accessible within the cluster for security
selector:
  app: product-catalog
ports:
- port: 80            # Service port (other services connect to this)
  targetPort: 3550    # Container port to forward traffic to
```

**Why ClusterIP?**
The product catalog contains sensitive information like pricing and inventory that should only be accessible from other internal services, not directly from the internet.

### 3. Authentication/Checkout Service

**Business Purpose:** Manages user sessions, authentication, and processes order checkouts.

**Technical Details:**
```yaml
# Key fields from auth-deployment.yaml
containers:
- name: auth
  image: gcr.io/google-samples/microservices-demo/checkoutservice:v0.8.0
  ports:
  - containerPort: 5050    # Checkout service internal port
  env:
  - name: PORT
    value: "5050"
  - name: PRODUCT_CATALOG_SERVICE_ADDR
    value: "product-catalog:80"    # Reference to product catalog service
  resources:
    requests:
      memory: "128Mi"
      cpu: "100m"
    limits:
      memory: "256Mi"
      cpu: "200m"
```

**Service Definition:**
```yaml
# auth-service.yaml
type: ClusterIP       # Internal access only for security
selector:
  app: auth-service
ports:
- port: 80            # Port other services use to access this service
  targetPort: 5050    # Container port to route to
```

**Security Considerations:**
This service handles sensitive user data and payment information, so it's kept internal using ClusterIP and would typically implement encryption for data in transit.

### 4. Recommendation Service

**Business Purpose:** Analyzes user behavior and provides personalized product recommendations.

**Technical Details:**
```yaml
# Key fields from recommendation-deployment.yaml
containers:
- name: recommendation-engine
  image: gcr.io/google-samples/microservices-demo/recommendationservice:v0.8.0
  ports:
  - containerPort: 8080
  env:
  - name: PORT
    value: "8080"
  - name: PRODUCT_CATALOG_SERVICE_ADDR
    value: "product-catalog:80"
  resources:
    requests:
      memory: "512Mi"    # Higher memory for ML processing
      cpu: "500m"        # Higher CPU (0.5 cores)
    limits:
      memory: "1Gi"
      cpu: "1"           # Can use up to 1 full CPU core
```

**Service Definition:**
```yaml
# recommendation-service.yaml
type: ClusterIP       # Internal access only
selector:
  app: recommendation
ports:
- port: 80
  targetPort: 8080
```

**Why higher resource requirements?**
The recommendation service performs complex ML inference to generate personalized suggestions, requiring significantly more compute and memory than the other services.

## Port Number Explanations

Understanding port configurations is critical in microservices:

1. **containerPort** - The port the application inside the container listens on
2. **port** - The port exposed by the Kubernetes Service
3. **targetPort** - The container port the Service forwards traffic to

**Example Flow:**
1. External user → LoadBalancer Service (port 80) → Frontend Pod (targetPort 8080)
2. Frontend Pod → Product Catalog Service (port 80) → Product Catalog Pod (targetPort 3550)

## Resource Requests and Limits Explained

Kubernetes uses resource requests and limits to manage container resources:

* **requests** - Guaranteed minimum resources for the container. Used for scheduling decisions.
* **limits** - Maximum resources the container can use. Containers exceeding limits may be throttled (CPU) or terminated (memory).

**Example resource calculations:**
- Frontend: 3 replicas × 100m CPU request = 300m CPU (0.3 cores) minimum cluster capacity needed
- Recommendation: 1 replica × 1 CPU limit = at most 1 core can be used by this service

## Service Types Comparison

| Service Type | Use Case | Project Example | External Access |
|-------------|----------|----------------|----------------|
| **ClusterIP** | Internal services | Catalog, Auth, Recommendations | No - only within cluster |
| **NodePort** | Limited external access | (Not used in our example) | Yes - via node IP and port |
| **LoadBalancer** | Public-facing services | Frontend | Yes - via cloud load balancer |

## Implementation Steps

### 1. Create the Namespace

```bash
kubectl apply -f ecommerce-namespace.yaml
```

### 2. Deploy Backend Services First

```bash
kubectl apply -f catalog-deployment.yaml -f catalog-service.yaml
kubectl apply -f auth-deployment.yaml -f auth-service.yaml
kubectl apply -f recommendation-deployment.yaml -f recommendation-service.yaml
```

### 3. Deploy Frontend Last 

```bash
kubectl apply -f frontend-deployment.yaml -f frontend-service.yaml
```

### 4. Verify Deployments

```bash
kubectl get pods -n shopfast
kubectl get services -n shopfast
```

## Testing Service Connectivity

```bash
# Create a temporary pod to test internal connections
kubectl run -n shopfast test-shell --rm -it --image=busybox -- sh

# From within the pod, test connections
wget -q -O- http://product-catalog/products
wget -q -O- http://auth-service/checkout
wget -q -O- http://recommendation/suggestions
```

## Expected Learning Outcomes

Working with this project will help you gain experience with:

1. **Kubernetes Service Types** - Understanding when to use ClusterIP vs LoadBalancer
2. **Resource Management** - Setting appropriate CPU and memory limits
3. **Service Discovery** - How services find and communicate with each other
4. **Environment Configuration** - Using environment variables for service discovery
5. **Microservices Architecture** - Building complex applications from independent components
6. **Debugging Techniques** - Troubleshooting connection and deployment issues

## Troubleshooting Guide

### Common Issues and Solutions

#### 1. Services Can't Communicate

**Symptoms:**
- Frontend shows errors when trying to access product catalog
- Logs show connection refused

**Diagnosis:**
```bash
# Check if service endpoints are configured correctly
kubectl get endpoints -n shopfast

# Check if service selector matches pod labels
kubectl describe service product-catalog -n shopfast
kubectl get pods -n shopfast --show-labels
```

**Potential Solutions:**
- Ensure service selectors match pod labels
- Verify services are in the same namespace
- Check if pods are running and ready

#### 2. Resource Constraints

**Symptoms:**
- Pods stuck in "Pending" state
- OOMKilled status

**Diagnosis:**
```bash
# Check pod status and events
kubectl describe pod [pod-name] -n shopfast

# Check node resource usage
kubectl top nodes
```

**Potential Solutions:**
- Adjust resource requests to be within cluster capacity
- Scale nodes or increase node size
- Reduce resource limits for non-critical services

## Extension Challenges

After getting the basic application working:

1. **Add Horizontal Pod Autoscaler** - Scale based on CPU or memory usage
2. **Implement Istio** - Add service mesh for advanced traffic management
3. **Set up Prometheus & Grafana** - Monitor service performance
4. **Configure Ingress** - Use Ingress instead of LoadBalancer
5. **Deploy with ArgoCD** - Implement GitOps workflow

## Conclusion

This project provides hands-on experience with a production-grade microservices architecture. By working through the deployment and configuration, you'll gain valuable skills in Kubernetes service management, networking, and resource optimization that directly translate to real-world enterprise environments.
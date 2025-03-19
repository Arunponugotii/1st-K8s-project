## This is 1st k8s project##

Here we will learn basic concepts like pods , replica, deployments, readiness etc ..

## Commands which i used to practice

# to create namespace
kubect apply -f namespace.yaml

# To create pods with 3 replica
kubectl apply -f techstart-website,yaml

# To create service under above namespace and attch to the above pods
kubectl apply -f website-service.yaml

# now verify if they were created or not 

kubectl get nodes
kubectl get all -n techstart-website

kubectl get pods
kubectl get ns
kubectl get svc

kubectl describe pod -n techstart-website <pod name>
# AKS Terraform

- clone repo on local
- we are using free tier account to create this cluster 
- Change the subscription id on main.tf
### run az login on laptop 
```
az login --use-device-code
```
### init and apply the terraform
```
terraform init
terraform plan
terraform apply
```

# In sidte the Eks client server procress
- connect to eks clinent server 

## run the below comnds

```bash
# Login to Azure
az login --use-device-code
```
# Get AKS credentials
```
az aks get-credentials \
  --resource-group aks-rg \
  --name demo-aks
```
# Verify nodes
```
kubectl get nodes
```
# Check cluster info
```
kubectl cluster-info
```
# View all pods
```
kubectl get pods -A
```

AKS cluster is now connected and ready for Kubernetes deployments.

now crete one deplyment and access it 

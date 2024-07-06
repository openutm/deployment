# OpenUTM Deployment

A repository to help with deployment of the OpenUTM toolset in your cloud.

## Steps

This example is based on **DigitalOcean** cloud.

### Introduction

1. Understand the general architecture of the system by reviewing the [OAUTH Infrastructure](oauth_infrastructure.md) document.
2. Create your own environment files by reviewing the [constructing environment files](constructing_environment_files.md)

### Pre-requisites

1. Installed and configured `doctl`, [link](https://docs.digitalocean.com/reference/doctl/how-to/install/)
2. Created Kubernetes Cluster, [link](https://docs.digitalocean.com/products/kubernetes/how-to/create-clusters/)
3. Created Load Balancer, [link](https://docs.digitalocean.com/products/kubernetes/how-to/add-load-balancers/)
4. You can connect to your Cluster, [link](https://docs.digitalocean.com/products/kubernetes/how-to/connect-to-cluster/)
5. Your domain sub zone points to DigitalOcean DNS, [link](https://docs.digitalocean.com/products/networking/dns/getting-started/dns-registrars/)

### Your deployment

**NOTE**: We will assume your sub-domain is `test.example.com`, and contact email is `test@example.com` - these need to be customized

1. Create A and CNAME records for your domain on the DigitalOcean NS

```bash
# SETUP env variables
export DOMAIN_NAME="test.example.com"
export ACME_CONTACT_EMAIL="test@example.com"
export LOAD_BALANCER_IP=$(doctl compute load-balancer list --format IP --no-header)

# SETUP A and CNAME
doctl compute domain records list $DOMAIN_NAME
doctl compute domain delete $DOMAIN_NAME -f
doctl compute domain create $DOMAIN_NAME
doctl compute domain records create $DOMAIN_NAME \
    --record-type "A" --record-name "$DOMAIN_NAME." \
    --record-data "$LOAD_BALANCER_IP" \
    --record-ttl "30"
doctl compute domain records create $DOMAIN_NAME \
    --record-type "CNAME" --record-name "*" \
    --record-data "$DOMAIN_NAME." \
    --record-ttl "30"
doctl compute domain records list $DOMAIN_NAME
```

2. Install `ingress-nginx`

```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update ingress-nginx
helm search repo ingress-nginx
helm install ingress-nginx ingress-nginx/ingress-nginx \
    --namespace ingress-nginx \
    --create-namespace
```

3. Install `cert-manager`

```bash
helm repo add jetstack https://charts.jetstack.io
helm repo update jetstack
helm search repo jetstack
helm install cert-manager jetstack/cert-manager \
    --namespace cert-manager \
    --create-namespace \
    --set installCRDs=true
```

4. Edit your `.env` files from `env.examples` folder, and place them in this structure:

```bash
└── kustomize
    ├── blender
    │   └── .env.blender
    ├── passport
    │   └── .env.passport
    └── spotlight
        └── .env.spotlight
```

5. Generate the OIDC key and deploy your applications

```bash
openssl genrsa -out kustomize/passport/oidc.key 4096
kubectl apply -k kustomize/
```

6. Create personal access token with full access to modify `domain`, [link](https://docs.digitalocean.com/reference/api/create-personal-access-token/), and create kubernetes secret from it

```bash
export DO_API_TOKEN=__YOUR TOKEN HERE__
kubectl create secret generic "digitalocean-dns" \
    --from-literal=access-token="$DO_API_TOKEN"
```

7. Edit `generate-from-templates.sh` and customize the following env variables

```bash
export DOMAIN_NAME="test.example.com"
export ACME_CONTACT_EMAIL="test@example.com"
```

8. Run the file to generate customized yaml files from templates

```bash
./generate-from-templates.sh
```

9. Create `Issuer`

```bash
kubectl apply -f issuer.yaml
```

10. Create root and wildcard `Certificate`

```bash
kubectl apply -f certificate-root.yaml
kubectl apply -f certificate-wcard.yaml
```

11. Create `Ingress`

```bash
kubectl apply -f ingress.yaml
```

It will take some time for all components to settle and acquire  certificates. After that, your apps should be accessible under the following domains with trusted certificates:

- `https://blender.$DOMAIN_NAME`
- `https://spotlight.$DOMAIN_NAME`
- `https://passport.$DOMAIN_NAME`

### Configuring your Installation
- TBC
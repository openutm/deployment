# OpenUTM Deployment

A repository to help with deployment of the OpenUTM toolset in your cloud.

## Steps

This example is based on **DigitalOcean** cloud, it uses the `kustomize` tool and `kubectl` so you can use it with your cloud with it.

### 🚀 Before You Begin

To ensure a smooth deployment process, follow these three steps:

1. 📄 **Understand the Architecture**
   Familiarize yourself with the system's architecture by reviewing the [.env file documentation](system-architecture-env-file-documentation.md). This will give you a clear picture of how the components interact.

2. 🔑 **Deploy and Connect**
   Once the `.env` files are created, deploy the systems. Since Flight Passport acts as the authentication bridge between the backend and frontend, you'll need to update the environment files with the correct variables after deployment. Reapply these updated variables as detailed in Step 3.

3. 🔗 **Link Components**
   Check out the [environment files documentation](linking-spotlight-blender-via-passport.md) to properly link Spotlight and Blender via Passport. This step ensures seamless integration between all components.

💬 **Need Help?**
If you run into any issues, feel free to reach out to us on Discord. We're here to help!

### Pre-requisites

1. Installed and configured `doctl`, [link](https://docs.digitalocean.com/reference/doctl/how-to/install/)
2. Created Kubernetes Cluster, [link](https://docs.digitalocean.com/products/kubernetes/how-to/create-clusters/)
3. You can connect to your Cluster, [link](https://docs.digitalocean.com/products/kubernetes/how-to/connect-to-cluster/)
4. Your domain sub zone points to DigitalOcean DNS, [link](https://docs.digitalocean.com/products/networking/dns/getting-started/dns-registrars/)
5. `openssl` installed (for generating keys)

### Your deployment

**NOTE**: We will assume your sub-domain is `test.example.com`, and contact email is `test@example.com` - these need to be customized

1. Install `caddy-ingress-controller`

    ```bash
    # SETUP env variables
    export ACME_CONTACT_EMAIL="test@example.com"

    helm repo add caddy-ingress-controller https://caddyserver.github.io/ingress/
    helm repo update
    helm install caddy-ingress-controller caddy-ingress-controller/caddy-ingress-controller \
        --namespace caddy-system \
        --create-namespace \
        --version 1.3.0 \
        --set ingressController.config.email="$ACME_CONTACT_EMAIL" \
        --set ingressController.config.acmeCA="https://acme-v02.api.letsencrypt.org/directory"
    ```

2. Create A and CNAME records for your domain on the DigitalOcean NS

    **Note**: Wait for the Load Balancer to be assigned an IP address. You can check this with `kubectl get svc -n caddy-system caddy-ingress-controller`.

    ```bash
    # SETUP env variables
    export DOMAIN_NAME="test.example.com"

    # Get the Load Balancer IP from the installed service
    export LOAD_BALANCER_IP=$(kubectl get svc -n caddy-system caddy-ingress-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}')

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

3. Create your `.env` files from the examples:

    ```bash
    cp env.examples/.blender.env.example kustomize/blender/.env.blender
    cp env.examples/.passport.env.example kustomize/passport/.env.passport
    cp env.examples/.spotlight.env.example kustomize/spotlight/.env.spotlight
    ```

    Then edit these new files with your specific configuration (database passwords, secrets, etc.).

4. Generate the OIDC key and deploy your applications

    > **Note:** Blender and Spotlight containers may restart or fail health checks initially until they are linked with valid Passport credentials (see "Configuring Passport" section below).

    ```bash
    openssl genrsa -out kustomize/passport/oidc.key 4096
    kubectl apply -k kustomize/
    ```

5. Generate `Ingress` manifest

    Export your domain name and run the generation script. This will replace placeholders in `templates/` and create `ingress.yaml`.

    ```bash
    export DOMAIN_NAME="test.example.com"
    ./generate-from-templates.sh
    ```

6. Create `Ingress`

    ```bash
    kubectl apply -f ingress.yaml
    ```

7. Verify the Deployment

    Check that all pods are running and healthy:

    ```bash
    kubectl get pods -n openutm
    ```

    It will take some time for all components to settle and acquire certificates. After that, your apps should be accessible under the following domains with trusted certificates:

    - `https://blender.$DOMAIN_NAME`
    - `https://spotlight.$DOMAIN_NAME`
    - `https://passport.$DOMAIN_NAME`

### Configuring Passport and subsequently Blender and Spotlight

The first step is to configure Flight Passport and once Flight Passport is up and running you will have to update the variables for Blender and Spotlight and re-deploy. Use the [linking documentation](linking-spotlight-blender-via-passport.md) to login to Passport and generate variables for Spotlight and Blender. Once these are setup, they need to be reapplied to the cluster.

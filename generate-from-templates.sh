export DOMAIN_NAME="utm.pingzone.ie"
export ACME_CONTACT_EMAIL="info+openutm@pingzone.ie"

for file_name in issuer certificate ingress; do
    (
        echo "cat <<EOF >${file_name}.yaml"
        cat templates/${file_name}-template.yaml
        echo "EOF"
    ) >${file_name}-temp.yaml
    . ${file_name}-temp.yaml

    rm -f ${file_name}-temp.yaml
done

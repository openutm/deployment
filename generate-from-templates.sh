export DOMAIN_NAME=utm.pingzone.ie

for file_name in issuer certificate ingress; do
    (
        echo "cat <<EOF >${file_name}.yaml"
        cat ${file_name}-template.yaml
        echo "EOF"
    ) >${file_name}-temp.yaml
    . ${file_name}-temp.yaml

    rm -f ${file_name}-temp.yaml
done
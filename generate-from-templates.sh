export DOMAIN_NAME="test.example.com"

for file_name in ingress; do
    (
        echo "cat <<EOF >${file_name}.yaml"
        cat templates/${file_name}-template.yaml
        echo "EOF"
    ) >${file_name}-temp.yaml
    . ${file_name}-temp.yaml

    rm -f ${file_name}-temp.yaml
done

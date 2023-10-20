# Running the script
After you configure authentication with Azure, just init and apply (no inputs are required):

`terraform init`

`terraform apply`

in AzureCLI

`az aks get-credentials -n "aks-name" -g "aks-resource-group-name `

create a file with deployment.yaml

`kubectl apply -f deployment.yaml`

try to access through application gateway public IP

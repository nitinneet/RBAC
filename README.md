# RBAC
rolebinding

# kubectl config use-context nitin-context
# kubectl config get-contexts


############### ClusterRolebuinding ############
# Create SA
kubectl create serviceaccount test-sa

# Create a Cluster Role Binding (Option)
kubectl create clusterrolebinding test-sa-binding --clusterrole=view --serviceaccount=default:test-sa

# Create the Secret
TOKEN=$(kubectl create token test-sa)
kubectl create secret generic test-sa-secret --from-literal=token=$TOKEN --namespace=default

# Associate the Secret with the Service Account
kubectl patch serviceaccount test-sa -p '{"secrets": [{"name": "test-sa-secret"}]}
# Retrieve the Secret Name
SECRET_NAME=$(kubectl get serviceaccount test-sa -o jsonpath='{.secrets[0].name}')

# Get the Token from the Secret:
TOKEN=$(kubectl get secret $SECRET_NAME -o jsonpath='{.data.token}' | base64 --decode)

########### RoleBinding ##############
#  Create the Service Account
kubectl create namespace test
kubectl create serviceaccount test -n test
# Create the Secret for the Service Account
TOKEN=$(kubectl create token test -n test)
kubectl create secret generic test-secret --from-literal=token=$TOKEN -n test


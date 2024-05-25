#!/bin/bash

# Ensure the script exits if any command fails and prints each command before execution
set -euo pipefail
trap 'echo "Error occurred at line $LINENO while executing command: $BASH_COMMAND"' ERR

# Variables
NAMESPACE=""
SERVICE_ACCOUNT_NAME=""
ROLE_NAME="full-access"
LOG_FILE="/tmp/rbac_$(date +'%Y%m%d_%H%M%S').log"

# Function to set up logging
setup_logging() {
  exec > >(tee -i "$LOG_FILE")
  exec 2>&1
  echo "Logging setup: Output will be captured in $LOG_FILE"
}

# Function to check if a Kubernetes namespace exists
namespace_exists() {
  local namespace="$1"
  kubectl get namespace "$namespace" &>/dev/null
}

# Function to create Service Account and Secret
create_service_account_and_secret() {
  local namespace="$1"
  echo "########## Creating Service Account and Secret in namespace \"$namespace\"... ##########"
  
  # Create Service Account
  kubectl create sa "$SERVICE_ACCOUNT_NAME" -n "$namespace"

  # Create Token for Service Account
  TOKEN=$(kubectl create token "$SERVICE_ACCOUNT_NAME" -n "$namespace")

  # Create Secret for Service Account
  kubectl create secret generic "${SERVICE_ACCOUNT_NAME}-secret" --from-literal=token="$TOKEN" -n "$namespace"
}

# Function to create a Role
create_role() {
  echo "########## Creating Role \"$ROLE_NAME\" in namespace \"$NAMESPACE\"... ##########"
  cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: $NAMESPACE
  name: $ROLE_NAME
rules:
- apiGroups: ["*"]
  resources: ["*"]
  verbs: ["*"]
EOF
}

# Function to create a RoleBinding
create_role_binding() {
  local sa_name="$1"
  local namespace="$2"
  echo "########## Creating RoleBinding for Service Account \"$sa_name\"... ##########"
  cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: ${ROLE_NAME}-binding
  namespace: $namespace
subjects:
- kind: ServiceAccount
  name: $sa_name
  namespace: $namespace
roleRef:
  kind: Role
  name: $ROLE_NAME
  apiGroup: rbac.authorization.k8s.io
EOF
}

# Main function
main() {
  setup_logging

  echo "########## Starting RBAC for $NAMESPACE... ##########"

  if ! namespace_exists "$NAMESPACE"; then
    echo "Namespace \"$NAMESPACE\" does not exist. Exiting script."
    exit 1
  fi

  create_service_account_and_secret "$NAMESPACE"
  create_role
  create_role_binding "$SERVICE_ACCOUNT_NAME" "$NAMESPACE"

  echo "########## Finished RBAC for $NAMESPACE... ##########"
  
  echo "########## Use the below token in kubeconfig file ##########"
  echo "$TOKEN"
}

# Call main function
main

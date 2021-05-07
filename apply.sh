#!/usr/bin/env bash

set -e

# This is a playground for Contour+OPA on minikube, to make experimenting easy.
# It's based on a tutorial that's intended for vanilla envoy+opa, so some adjustments
# have been made.
#
# This requires minikube, kubectl, kubectx and curl.
#
# OPA+Envoy Tutorial: https://www.openpolicyagent.org/docs/v0.22.0/envoy-authorization/

minikube start --embed-certs --profile=minikube

kubectx minikube
kubens default

# We need a cert-manager to be able to generate certificates for communication with OPA.
# Contour does not support External Authorization without TLS being enabled.
kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.3.1/cert-manager.yaml

kubectl create ns projectcontour

# The services do not come up that quickly and without waiting it fails to
# apply cleanly due to the webhook. If this fails, please try to adjust the time up.
echo "Waiting a bit for cert-manager to settle"
sleep 60;

kubectl apply -n projectcontour -f issuer.yaml

# Default contour installation, will end up in ns `projectcontour`
kubectl apply -n projectcontour -f https://projectcontour.io/quickstart/contour.yaml

# This is a cert needed for Contour<->Envoy comms, which is not created per default
#kubectl apply -n projectcontour -f envoy_cert.yaml

kubectl apply -n projectcontour -f opa_deployment.yaml

# Deploys the rego files to be used by OPA.
# This is not a recommended way to deploy the config, but is used within the tutorial.
kubectl create -n projectcontour secret generic opa-policy --from-file policy.rego

# Unlike in the tutorial, we deploy the app stand-alone, without side-cars.
kubectl apply -n default -f app_deployment.yaml

# Ingress parts
# k port-forward -n projectcontour svc/envoy 9080:443

# Default tokens from the tutorial, to be used with curl, like
# `curl -i -k -H "Authorization: Bearer "$ALICE_TOKEN"" https://localhost:9080/people`
# once envoy is locally forwarded.

export ALICE_TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiZ3Vlc3QiLCJzdWIiOiJZV3hwWTJVPSIsIm5iZiI6MTUxNDg1MTEzOSwiZXhwIjoxNjQxMDgxNTM5fQ.K5DnnbbIOspRbpCr2IKXE9cPVatGOCBrBQobQmBmaeU"
export BOB_TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiYWRtaW4iLCJzdWIiOiJZbTlpIiwibmJmIjoxNTE0ODUxMTM5LCJleHAiOjE2NDEwODE1Mzl9.WCxNAveAVAdRCmkpIObOTaSd0AJRECY2Ch2Qdic3kU8"

echo "It will still take a bit of time for contour+envoy to create the certificates and settle"
echo "Once envoy is up, you can proceed with something like:"
echo 'k port-forward -n projectcontour svc/envoy 9080:443'
echo 'curl -i -k -H "Authorization: Bearer "$ALICE_TOKEN"" https://localhost:9080/people'

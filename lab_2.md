# Instalando o Dashboard do Kubernets e ativando métricas

# No minikube é mais simples:

$ minikube addons enable metrics-server
💡  metrics-server is an addon maintained by Kubernetes. For any concerns contact minikube on GitHub.
You can view the list of minikube maintainers at: https://github.com/kubernetes/minikube/blob/master/OWNERS
    ▪ Using image registry.k8s.io/metrics-server/metrics-server:v0.6.3
🌟  The 'metrics-server' addon is enabled

# e depois:

$ minikube dashboard
🤔  Verifying dashboard health ...
🚀  Launching proxy ...
🤔  Verifying proxy health ...
🎉  Opening http://127.0.0.1:37853/api/v1/namespaces/kubernetes-dashboard/services/http:kubernetes-dashboard:/proxy/ in your default browser...

# fim, hahaha, agora vamos fazer isso no "mundo real". Os passos a seguir são executados no nó MASTER.


# Primeiro precisamos instalar o servidor de métricas, primeiro vamos baixar os componentes

$ curl -LO https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# como não temos um certificado real, precisamos ajustar uma configuração nos componentes:

$ vi components.yaml
...
spec:
hostNetwork: true    <==
containers:
    - args:
        - --cert-dir=/tmp
        - --secure-port=4443
        - --kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname
        - --kubelet-use-node-status-port
        - --metric-resolution=15s
        - --kubelet-insecure-tls   <==
...

# salve e saia do arquivo. Agora vamos aplicar o componente no nosso cluster:

$ kubectl apply -f components.yaml
serviceaccount/metrics-server created
clusterrole.rbac.authorization.k8s.io/system:aggregated-metrics-reader created
clusterrole.rbac.authorization.k8s.io/system:metrics-server created
rolebinding.rbac.authorization.k8s.io/metrics-server-auth-reader created
clusterrolebinding.rbac.authorization.k8s.io/metrics-server:system:auth-delegator created
clusterrolebinding.rbac.authorization.k8s.io/system:metrics-server created
service/metrics-server created
deployment.apps/metrics-server created
apiservice.apiregistration.k8s.io/v1beta1.metrics.k8s.io created

# vamos verificar se subiu a interface:
$ kubectl get pods -n kube-system
NAME                                            READY   STATUS    RESTARTS   AGE
...
metrics-server-7c94c94795-t7h6j                 1/1     Running   0          29s

# quando terminar de levantar, conseguimos avaliar os nós do cluster com o comando:

$ kubectl top nodes
NAME                     CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%   
k8smaster.facom.local    106m         5%     1976Mi          51%       
k8sworker1.facom.local   23m          2%     1149Mi          61%       
k8sworker2.facom.local   20m          2%     1148Mi          61% 

# e para uma visão dos PODs

$ kubectl top pod 
NAME                        CPU(cores)   MEMORY(bytes)   
nginx-app-5777b5f95-r6r2k   0m           2Mi             
nginx-app-5777b5f95-s8jvl   0m           2Mi             

$ kubectl top pod -n kube-system
NAME                                            CPU(cores)   MEMORY(bytes)   
calico-kube-controllers-658d97c59c-6nfhc        2m           11Mi            
calico-node-prlb9                               17m          74Mi            
calico-node-rc6mb                               21m          73Mi            
calico-node-tqvm6                               14m          73Mi            
coredns-5dd5756b68-dfrh4                        1m           11Mi            
coredns-5dd5756b68-qkwgd                        1m           11Mi            
etcd-k8smaster.facom.local                      15m          39Mi            
kube-apiserver-k8smaster.facom.local            39m          303Mi           
kube-controller-manager-k8smaster.facom.local   11m          43Mi            
kube-proxy-n9l2t                                1m           13Mi            
kube-proxy-xzmhk                                1m           20Mi            
kube-proxy-zm56n                                1m           20Mi            
kube-scheduler-k8smaster.facom.local            4m           17Mi            
metrics-server-7c94c94795-t7h6j                 3m           13Mi

# Pronto. Próximo passo é configurar o Dashboard do Kubernets.

# Primeiro precisamos instalar o helm:

$ curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
$ chmod +x get_helm.sh
$ ./get_helm.sh
Downloading https://get.helm.sh/helm-v3.12.3-linux-amd64.tar.gz
Verifying checksum... Done.
Preparing to install helm into /usr/local/bin
helm installed into /usr/local/bin/helm

# agora vamos usar o helm para instalar o dashboard

$ helm repo add kubernetes-dashboard https://kubernetes.github.io/dashboard/
"kubernetes-dashboard" has been added to your repositories

$ helm repo list
NAME                    URL                                    
kubernetes-dashboard    https://kubernetes.github.io/dashboard/

# Agora vamos instalar, de fato, o dashboard:

$ helm upgrade --install kubernetes-dashboard kubernetes-dashboard/kubernetes-dashboard --create-namespace --namespace kubernetes-dashboard
Release "kubernetes-dashboard" does not exist. Installing it now.
NAME: kubernetes-dashboard
LAST DEPLOYED: Tue Sep 19 15:09:30 2023
NAMESPACE: kubernetes-dashboard
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
*********************************************************************************
*** PLEASE BE PATIENT: kubernetes-dashboard may take a few minutes to install ***
*********************************************************************************

Get the Kubernetes Dashboard URL by running:
  export POD_NAME=$(kubectl get pods -n kubernetes-dashboard -l "app.kubernetes.io/name=kubernetes-dashboard,app.kubernetes.io/instance=kubernetes-dashboard" -o jsonpath="{.items[0].metadata.name}")
  echo https://127.0.0.1:8443/
  kubectl -n kubernetes-dashboard port-forward $POD_NAME 8443:8443


# pronto, nosso dashboard está pronto para uso. Agora temos que criar um usuário:

$ nano k8s-dashboard-account.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kube-system

# e vamos aplicar o usuário no sistema:

$ kubectl create -f k8s-dashboard-account.yaml
serviceaccount/admin-user created
clusterrolebinding.rbac.authorization.k8s.io/admin-user created

# agora vamos gerar o token do usuário admin:

$ kubectl -n kube-system  create token admin-user
eyJhbGciOiJSUzI1NiIsImtpZCI6ImVMVFd6UURkVUZJekhiU2hrdWVZMlJIWm55NzRlLWY0RFRyMWpDTVNOYncifQ.eyJhdWQiOlsiaHR0cHM6Ly9rdWJlcm5ldGVzLmRlZmF1bHQuc3ZjLmNsdXN0ZXIubG9jYWwiXSwiZXhwIjoxNjk1MTQwNTA3LCJpYXQiOjE2OTUxMzY5MDcsImlzcyI6Imh0dHBzOi8va3ViZXJuZXRlcy5kZWZhdWx0LnN2Yy5jbHVzdGVyLmxvY2FsIiwia3ViZXJuZXRlcy5pbyI6eyJuYW1lc3BhY2UiOiJrdWJlLXN5c3RlbSIsInNlcnZpY2VhY2NvdW50Ijp7Im5hbWUiOiJhZG1pbi11c2VyIiwidWlkIjoiZDcxOWEyZGUtNDgzOC00MDI5LWE4MjAtZjFjOTEwMWMxMWU4In19LCJuYmYiOjE2OTUxMzY5MDcsInN1YiI6InN5c3RlbTpzZXJ2aWNlYWNjb3VudDprdWJlLXN5c3RlbTphZG1pbi11c2VyIn0.fN8adchEOc8RkPUP2VdA-YhlkDPRWwDiSLgkGX6nfZOAaZMM5RzvpOyFVvoGsYc2NNXVWuC9IPeQCU0th2-2ZWYDD1mrEGnhLSBNnsSit2ZM_1-01rVBT1mJ-RNjGswp28LiDFIi8v2p_Yf3-OBEjLmLdSZjEJHcBKaJV4-einkhbJPsPDZl1TKne5D-_-KSAQjC8IjKshROrxxa-jGHKSVTYhzETffK15tBHhUeFGNe-gexkjwLOxB_P1xGlv3prnKQmM3iGH5Fzff5m9lhYVj3qI8EA4z65MERqepLL9-AlwBJlGmvRxbc6XTXrgLC6gVO-gf7HelGpjtN1QkV0A

# pronto, copie o token na tela de login e vai dar certo.







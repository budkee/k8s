# Minicube

- [O que é Minicube?](sobre.md#o-que-é-minikube)


## Instalando as ferramentas necessárias

> Pra essa prática, você já deve ter a VM com o sabor `Debian 12 Bookworm` rodando pra executar os próximos comando no terminal.  
> - [Preparando e subindo a VM](debian_12-virtualbox.pdf)

### Instalando o minikube e sua CLI (kubectl)

> Enquanto o `minikube` cria e executa os clusters K8s locais, o `kubectl` realiza toda interação necessária para qualquer cluster (local ou remoto).

```
$ curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube_latest_amd64.deb
$ dpkg -i minikube_latest_amd64.deb
$ minikube version          # Verificando a instalação
$ snap install kubectl --classic
```
> Caso dê algum erro dizendo que o comando não foi encontrado, basta executar um `sudo apt install` para resolver.

> - Também pode acontecer do sistema não reconhecer seu usuário pertencente ao grupo de superusuários. Nesse caso basta executar `usermod -aG sudo <usuario>` e reiniciar o terminal.

> - Outro erro que pode ocorrer é na hora de instalar a CLI com o `snap`. Uma alternativa é usar o `curl`:

```
$ curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/arm64/kubectl"
$ chmod +x kubectl
$ sudo mv kubectl /usr/local/bin/
$ kubectl version --client        # Verificando a instalação
```
> - [Instalando `kubectl` com `curl`](https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/#install-kubectl-binary-with-curl-on-linux)

### Instalando o Driver | Docker

> Para que o K8s possa funcionar vamos precisamos que um Driver, como o Docker, esteja pronto nessa máquina. Mas antes, vamos primeiro preparar o repositório estável do Docker:

```
$ sudo apt-get update
$ sudo install -m 0755 -d /etc/apt/keyrings
$ sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
$ sudo chmod a+r /etc/apt/keyrings/docker.asc
$ echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
$ sudo apt-get update
```
> Agora que a gente vai de fato instalar as ferramentas do docker e verificar sua instalação:
```
$ sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
$ docker --version
```
> Por fim, vamos adicionar o nosso usuário ao grupo docker com o seguinte comando:

```$ adduser usuario docker```

> Ou, caso nao reconheça o `adduser`:

```$ sudo usermod -aG docker $USER```

> Em seguida, faça logout e login no terminal novamente para que as atualizações tenham efeito. Você pode confirmar com o comando `groups` para ver se deu tudo certo.

- [Instalando Docker usando o Repositório Oficial](https://docs.docker.com/engine/install/debian/#install-using-the-repository)
- [Usando o Docker com um usuario não `root`](https://docs.docker.com/engine/install/linux-postinstall/#manage-docker-as-a-non-root-user)

## Subindo o Minikube

> Agora vamos levantar o sistema:

```
$ minikube start
😄  minikube v1.36.0 on Debian 12.11 (arm64)
✨  Automatically selected the docker driver

🧯  The requested memory allocation of 1975MiB does not leave room for system overhead (total system memory: 1975MiB). You may face stability issues.
💡  Suggestion: Start minikube with less memory allocated: 'minikube start --memory=1975mb'

📌  Using Docker driver with root privileges
👍  Starting "minikube" primary control-plane node in "minikube" cluster
🚜  Pulling base image v0.0.47 ...
💾  Downloading Kubernetes v1.33.1 preload ...
    > preloaded-images-k8s-v18-v1...:  327.15 MiB / 327.15 MiB  100.00% 19.16 M
    > gcr.io/k8s-minikube/kicbase...:  463.69 MiB / 463.69 MiB  100.00% 11.30 M
🔥  Creating docker container (CPUs=2, Memory=1975MB) ...
🐳  Preparing Kubernetes v1.33.1 on Docker 28.1.1 ...
    ▪ Generating certificates and keys ...
    ▪ Booting up control plane ...
    ▪ Configuring RBAC rules ...
🔗  Configuring bridge CNI (Container Networking Interface) ...
🔎  Verifying Kubernetes components...
    ▪ Using image gcr.io/k8s-minikube/storage-provisioner:v5
🌟  Enabled addons: default-storageclass, storage-provisioner
🏄  Done! kubectl is now configured to use "minikube" cluster and "default" namespace by default
```

> Agora os testes:

```
$ kubectl get nodes
NAME       STATUS   ROLES           AGE    VERSION
minikube   Ready    control-plane   4m8s   v1.27.3
```

> Verificar os pods

```
$ kubectl get pods
No resources found in default namespace.
```

> Verificar as implantações
```
$ kubectl get deployment
No resources found in default namespace.
```

```
$ kubectl get deployment --all-namespaces
NAMESPACE     NAME      READY   UP-TO-DATE   AVAILABLE   AGE
kube-system   coredns   1/1     1            1           4m30s
```

> Auto Complete
```
echo source <(kubectl completion bash) >> .bashrc
```

> Entrando no minikube
```
$ minikube ip
192.168.49.2

$ minikube ssh
docker@minikube:~$ 
```

> para remover o minikube
```
$ minikube delete
```

> Agora vamos criar um cluster com múltiplas máquinas. Para ativarmos nosso cluster, primeiro nós vamos mudar os nomes das nossa máquinas:

```
$ hostnamectl set-hostname "k8smaster.facom.local"
$ bash
```
> e fazer o mesmo para cada um dos nós:

### node01
```
$ hostnamectl set-hostname "k8sworker1.facom.local"
$ bash
```
### node02
```
$ hostnamectl set-hostname "k8sworker2.facom.local"
$bash
```
> e em CADA NÓ, vamos adicionar essa informação ao /etc/hosts. Fique atendo ao IP dos hosts
```
$ vi /etc/hosts
# Kubernet Cluster
192.168.1.210   k8smaster.facom.local k8smaster
192.168.1.191   k8sworker1.facom.local k8sworker1
192.168.1.192   k8sworker2.facom.local k8sworker2
```

> Agora nós vamos desabilitar a SWAP e ativar os parâmetros necessários do kernel
```
$ swapoff -a
$ sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

$ tee /etc/modules-load.d/containerd.conf <<EOF
overlay
br_netfilter
EOF

$ modprobe overlay
$ modprobe br_netfilter
```

> e agora tornar isso perene no boot:
```
$ tee /etc/sysctl.d/kubernetes.conf <<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
```
> e ativar
```
$ sysctl --system
...
* Applying /etc/sysctl.d/kubernetes.conf ...
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
```
> Agora vocês devem instalar o Docker
```
$ curl -fSsL https://get.docker.com | bash
```
> é necessário agora informar o containerd para usar o systemd:
```
$ containerd config default | sudo tee /etc/containerd/config.toml >/dev/null 2>&1
$ sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g' /etc/containerd/config.toml
$ systemctl restart containerd
$ systemctl enable containerd
```
> O próximo passo é adicionar as chaves e instalar o kubernetes
```
$ curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo gpg --dearmour -o /etc/apt/trusted.gpg.d/kubernetes-xenial.gpg
$ apt-add-repository "deb http://apt.kubernetes.io/ kubernetes-xenial main"
```
> Agora vamos instalar as aplicações necessárias:
```
$ apt install -y kubelet kubeadm kubectl
```
> e marcar para o sistema fixar os pacotes
```
$ apt-mark hold kubelet kubeadm kubectl
kubelet set on hold.
kubeadm set on hold.
kubectl set on hold.
```

> Feito isso, vamos inicializar  o cluster kubernetes com o kubeadm no nó Master
```
$ kubeadm init --control-plane-endpoint=k8smaster.facom.local
[init] Using Kubernetes version: v1.28.2
[preflight] Running pre-flight checks
[preflight] Pulling images required for setting up a Kubernetes cluster
[preflight] This might take a minute or two, depending on the speed of your internet connection
[preflight] You can also perform this action in beforehand using 'kubeadm config images pull'
...
[control-plane] Creating static Pod manifest for "kube-apiserver"
[control-plane] Creating static Pod manifest for "kube-controller-manager"
[control-plane] Creating static Pod manifest for "kube-scheduler"
[kubelet-start] Writing kubelet environment file with flags to file "/var/lib/kubelet/kubeadm-flags.env"
[kubelet-start] Writing kubelet configuration to file "/var/lib/kubelet/config.yaml"
[kubelet-start] Starting the kubelet
[wait-control-plane] Waiting for the kubelet to boot up the control plane as static Pods from directory "/etc/kubernetes/manifests". This can take up to 4m0s
...
Your Kubernetes control-plane has initialized successfully!

To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

Alternatively, if you are the root user, you can run:

  export KUBECONFIG=/etc/kubernetes/admin.conf

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  https://kubernetes.io/docs/concepts/cluster-administration/addons/

You can now join any number of control-plane nodes by copying certificate authorities
and service account keys on each node and then running the following as root:

  kubeadm join k8smaster.facom.local:6443 --token aufdm7.r3lp5obfirzy4klj \
        --discovery-token-ca-cert-hash sha256:045ae87994f93b31611b39075b9a04a1d506e78fd7b343423114045e80c52d9e \
        --control-plane 

Then you can join any number of worker nodes by running the following on each as root:

kubeadm join k8smaster.facom.local:6443 --token aufdm7.r3lp5obfirzy4klj \
        --discovery-token-ca-cert-hash sha256:045ae87994f93b31611b39075b9a04a1d506e78fd7b343423114045e80c52d9e
```

> ao terminar ele vai mostrar a mensagem necessária para fazer o 'join' dos nós. Para interagir com o cluster, vamos rodar os comandos no master:
```
$ mkdir -p $HOME/.kube
$ cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
$ chown $(id -u):$(id -g) $HOME/.kube/config
```
> podemos perceber que não temos nenhum nó no cluster ainda
```
$ kubectl cluster-info
Kubernetes control plane is running at https://k8smaster.facom.local:6443
CoreDNS is running at https://k8smaster.facom.local:6443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy

To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.

$ kubectl get nodes
NAME                    STATUS     ROLES           AGE     VERSION
k8smaster.facom.local   NotReady   control-plane   3m50s   v1.28.2
```

> Agora vamos adicionar os nós no cluster (executar em cada nó):
```
$ kubeadm join k8smaster.facom.local:6443 --token aufdm7.r3lp5obfirzy4klj \
        --discovery-token-ca-cert-hash sha256:045ae87994f93b31611b39075b9a04a1d506e78fd7b343423114045e80c52d9e

[preflight] Running pre-flight checks
[preflight] Reading configuration from the cluster...
[preflight] FYI: You can look at this config file with 'kubectl -n kube-system get cm kubeadm-config -o yaml'
[kubelet-start] Writing kubelet configuration to file "/var/lib/kubelet/config.yaml"
[kubelet-start] Writing kubelet environment file with flags to file "/var/lib/kubelet/kubeadm-flags.env"
[kubelet-start] Starting the kubelet
[kubelet-start] Waiting for the kubelet to perform the TLS Bootstrap...

This node has joined the cluster:
* Certificate signing request was sent to apiserver and a response was received.
* The Kubelet was informed of the new secure connection details.

Run 'kubectl get nodes' on the control-plane to see this node join the cluster.
```
> Vejamos os nós entrando no cluster:
```
root@k8smaster:~# kubectl get nodes
NAME                     STATUS     ROLES           AGE     VERSION
k8smaster.facom.local    NotReady   control-plane   5m49s   v1.28.2
```
> após no node01
```
root@k8smaster:~# kubectl get nodes
NAME                     STATUS     ROLES           AGE     VERSION
k8smaster.facom.local    NotReady   control-plane   6m14s   v1.28.2
k8sworker1.facom.local   NotReady   <none>          40s     v1.28.2
```
> após o node02
```
root@k8smaster:~# kubectl get nodes
NAME                     STATUS     ROLES           AGE     VERSION
k8smaster.facom.local    NotReady   control-plane   6m57s   v1.28.2
k8sworker1.facom.local   NotReady   <none>          83s     v1.28.2
k8sworker2.facom.local   NotReady   <none>          28s     v1.28.2
```

> Notem que os nós estão `NotReady`, isso acontece porque precisamos instalar um CNI (Container Network Interface) ou um plugin de rede como Calico, Flannel ou Weave-net. Vamos instalar o Calico. No Master:
```
$ kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.25.0/manifests/calico.yaml
poddisruptionbudget.policy/calico-kube-controllers created
serviceaccount/calico-kube-controllers created
serviceaccount/calico-node created
configmap/calico-config created
customresourcedefinition.apiextensions.k8s.io/bgpconfigurations.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/bgppeers.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/blockaffinities.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/caliconodestatuses.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/clusterinformations.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/felixconfigurations.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/globalnetworkpolicies.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/globalnetworksets.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/hostendpoints.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/ipamblocks.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/ipamconfigs.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/ipamhandles.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/ippools.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/ipreservations.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/kubecontrollersconfigurations.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/networkpolicies.crd.projectcalico.org created
customresourcedefinition.apiextensions.k8s.io/networksets.crd.projectcalico.org created
clusterrole.rbac.authorization.k8s.io/calico-kube-controllers created
clusterrole.rbac.authorization.k8s.io/calico-node created
clusterrolebinding.rbac.authorization.k8s.io/calico-kube-controllers created
clusterrolebinding.rbac.authorization.k8s.io/calico-node created
daemonset.apps/calico-node created
deployment.apps/calico-kube-controllers created
```

> Percebam que agora temos os pods do gerenciamento de rede rodando:
```
$ kubectl get pods -n kube-system
NAME                                            READY   STATUS     RESTARTS   AGE
calico-kube-controllers-658d97c59c-6nfhc        0/1     Pending    0          43s
calico-node-prlb9                               0/1     Init:1/3   0          43s
calico-node-rc6mb                               0/1     Init:0/3   0          43s
calico-node-tqvm6                               0/1     Init:0/3   0          43s
```
> e também que os nós agora estão Ready (prontos para uso)
```
$ kubectl get nodes
NAME                     STATUS   ROLES           AGE     VERSION
k8smaster.facom.local    Ready    control-plane   11m     v1.28.2
k8sworker1.facom.local   Ready    <none>          5m28s   v1.28.2
k8sworker2.facom.local   Ready    <none>          4m33s   v1.28.2
```

> Agora vamos testar o nosso cluster kubernetes:
```
$ kubectl create deployment nginx-app --image=nginx --replicas=2
deployment.apps/nginx-app created

$ kubectl get deployment nginx-app
NAME        READY   UP-TO-DATE   AVAILABLE   AGE
nginx-app   0/2     2            0           8s

$ kubectl get deployment nginx-app
NAME        READY   UP-TO-DATE   AVAILABLE   AGE
nginx-app   1/2     2            1           37s

$ kubectl get deployment nginx-app
NAME        READY   UP-TO-DATE   AVAILABLE   AGE
nginx-app   2/2     2            2           49s
```
> e vamos expor a porta para o nosso deployment
```
$ kubectl expose deployment nginx-app --type=NodePort --port=80
service/nginx-app exposed
```
> vamos validar que o serviço está ativo:
```
$ kubectl get svc nginx-app
NAME        TYPE       CLUSTER-IP       EXTERNAL-IP   PORT(S)        AGE
nginx-app   NodePort   10.108.129.187   <none>        80:31522/TCP   29s

$ kubectl describe svc nginx-app
Name:                     nginx-app
Namespace:                default
Labels:                   app=nginx-app
Annotations:              <none>
Selector:                 app=nginx-app
Type:                     NodePort
IP Family Policy:         SingleStack
IP Families:              IPv4
IP:                       10.108.129.187
IPs:                      10.108.129.187
Port:                     <unset>  80/TCP
TargetPort:               80/TCP
NodePort:                 <unset>  31522/TCP
Endpoints:                172.16.252.132:80,172.16.55.65:80
Session Affinity:         None
External Traffic Policy:  Cluster
Events:                   <none>
```
> No meu caso, o IP é o do Master e a Porta é a vinculada: http://192.168.1.148:31522/










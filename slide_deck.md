# **Slide Deck Outline (20 minutes)**

## **Slide 1: Title Slide (1 minute)**
- **Title**: *Deploying and Demonstrating Cilium Cluster Mesh for Resilient Multi-Cluster Networking*
- **Subtitle**: Focus on Global Services, Ingress, and Secure Communication
- **Your Name & Role**
- **Session Overview**: Brief introduction to the agenda.

---

## **Slide 2: Introduction to Cilium Cluster Mesh (2 minutes)**
Cilium was first released in July 2017. It was developed to solve the challenges of securing and managing network traffic for microservices in modern containerized environments like Kubernetes. The primary objective of Cilium was to use eBPF (extended Berkeley Packet Filter), a technology in the Linux kernel, to improve observability, networking, and security within clusters.
- **What is Cilium Cluster Mesh?**
  - Multi-cluster networking powered by Cilium.
  - Enables seamless inter-cluster communication.
- **Key Features**:
  - Global Services.
  - Cross-cluster service discovery.
  - Load balancing across clusters.

---

## **Slide 3: Cilium and eBPF (2 minutes)**
- **Cilium Overview**:
  - Advanced Container Network Interface (CNI) leveraging eBPF.
- **Why eBPF?**
  - Kernel-level networking, observability, and security.
  - Low latency, high performance.
  - Pod routing and network policy enforcement.

---

## **Slide 4: Key Benefits of Cilium Cluster Mesh (2 minutes)**
- **Resilience and High Availability**:
  - Failover capabilities across clusters.
  - Load balancing for resource optimization.
- **Seamless Service Discovery**:
  - Global DNS-based service discovery across clusters.
- **Scalability and Security**:
  - Multi-cluster, multi-region networking with encrypted traffic.

---

## **Slide 5: Architecture Overview (3 minutes)**
- **Prerequisites**:
  - Unique CIDR ranges, node IP connectivity, and shared CA.
  - Load balancers with MetalLB (for on-prem clusters).
- **Architecture Diagram**: Show how clusters are interconnected.
- **Components Used**:
  - RKE2, Helm, ArgoCD, MetalLB, NGINX, and more.

---

## **Slide 6: Global Services (3 minutes)**
- **What are Global Services?**
  - Unified service discovery and load balancing across clusters.
- **Scenarios**:
  - Single AZ, multi-AZ, and multi-region deployments.
  - Improved resiliency, reduced latency, and fault tolerance.
- **How It Works**:
  - eBPF-driven load balancing.
  - DNS-based service discovery across clusters.

---

## **Slide 7: Shared Ingress (2 minutes)**
- **Challenges with Traditional Ingress Controllers**:
  - Endpoint availability issues across clusters.
- **NGINX Ingress with Cilium**:
  - Shared ingress using `nginx.ingress.kubernetes.io/service-upstream`.
  - Balances traffic across clusters even without local endpoints.
- **Role of `CiliumEndpoints`**:
  - Enhanced metadata and visibility for optimized traffic routing.

---

## **Slide 8: Lightweight Service Mesh (2 minutes)**
- **Cilium as a Lightweight Service Mesh**:
  - Service mesh-like functionality without sidecar proxies.
- **eBPF vs Traditional Service Mesh**:
  - Lower overhead, kernel-level routing, and security.
- **SPIRE/SPIFFE for Workload Security**:
  - Securing workloads with identities.

---

## **Slide 9: Node Encryption with Wireguard (1 minute)**
- **Wireguard Integration**:
  - Encrypt traffic between nodes.
  - Lightweight, fast, and easy to deploy with Cilium.

---

## **Slide 10: Securing CoreDNS with CiliumNetworkPolicy (2 minutes)**

- **Why Secure CoreDNS?**
  - CoreDNS is critical for service discovery in Kubernetes clusters.
  - Ensuring that only authorized pods can communicate with CoreDNS adds an extra layer of security to your cluster.

- **CiliumNetworkPolicy Overview**:
  - Cilium’s `CiliumNetworkPolicy` is used to enforce fine-grained network security policies.
  - It allows you to define both L3/L4 (IP, port) and L7 (protocol) policies using eBPF, giving precise control over which pods can access specific services.

- **Securing CoreDNS Example**:
  - Use `CiliumNetworkPolicy` to restrict access to the CoreDNS service, allowing ingress from any endpoint in the `kube-system`, `metallb-system`, and `ingress-nginx` namespaces.
  - Example policy:
    ```yaml
    apiVersion: cilium.io/v2
    kind: CiliumNetworkPolicy
    metadata:
      name: coredns-restriction
      namespace: kube-system
    spec:
      endpointSelector:
        matchLabels:
          k8s-app: kube-dns
      ingress:
      - fromEndpoints:
        - matchLabels:
            k8s:io.kubernetes.pod.namespace: kube-system
        - matchLabels:
            k8s:io.kubernetes.pod.namespace: metallb-system
        - matchLabels:
            k8s:io.kubernetes.pod.namespace: ingress-nginx
        - matchLabels:
            k8s:io.kubernetes.pod.namespace: cilium-spire
        - matchLabels:
            k8s:io.kubernetes.pod.namespace: monitoring
        - matchLabels:
            k8s:io.kubernetes.pod.namespace: kube-node-lease
        - matchLabels:
            k8s:io.kubernetes.pod.namespace: kube-public
        - matchLabels:
            k8s:io.kubernetes.pod.namespace: storage
        - matchLabels:
            k8s:io.kubernetes.pod.namespace: allow-dns-access
        toPorts:
        - ports:
          - port: "53"
            protocol: UDP
          - port: "53"
            protocol: TCP
    ```

- **Key Benefits**:
  - Only allows necessary components (e.g., system services, ingress controllers, load balancers) to access CoreDNS.
  - Reduces potential attack surface by limiting the number of services that can query DNS.
  - Easily managed with Cilium’s dynamic, eBPF-based policies, ensuring high performance and security.

---

## **Slide 11: Demo Overview (2 minutes)**
- **Demo Preview**:
  - Deploy Cilium Cluster Mesh across two clusters.
  - Demonstrate global services, shared ingress, and service failover.
- **Key Goals**:
  - Show multi-cluster communication and load balancing in action.
  - Highlight secure communication with Wireguard.

---

# **Demo Outline (20 minutes)**

## **Step 1: Setup Overview (2 minutes)**
- Show the environment setup:
  - Two RKE2 clusters with Cilium installed.
  - CIDR ranges, MetalLB load balancers, and shared CA setup via Helm chart.

---

## **Step 2: Deploy Cilium Cluster Mesh (5 minutes)**
- Use `helm` and `kubectl` to deploy the Cilium Cluster Mesh.
- Show how the clusters connect and recognize each other.

---

## **Step 3: Deploy Global Service (5 minutes)**
- Deploy a sample application (e.g., NGINX) across clusters.
- Show the global service routing using DNS-based service discovery.
- Demonstrate load balancing between the two clusters.

**Use** the following links:

```
grafana creds: admin/PNlYcVNil0lfQs0pZ9jaNkWXgPXPLGVifkCkanF6

nslookup http://lgtm-distributed-mimir-nginx.monitoring.svc.cluster.local

# shared ingress
ingress.cluster1.kubula.internal
ingress.cluster2.kubula.internal

# scale one deployment down to 0 and retry

# sahred services
For this either rebel-base of x-web. x-web is only deployed on cluster1, but cluster2 can access it
rebel-base.cluster1.kubula.internal
rebel-base.cluster2.kubula.internal
```

---

## **Step 5: Mutual Auth (1 minute)**

Verify the list of attested agents:

```
kubectl exec -n cilium-spire spire-server-0 -c spire-server -- /opt/spire/bin/spire-server agent list
```

Verify SPIFFE Identities:

```
kubectl exec -n cilium-spire spire-server-0 -c spire-server -- /opt/spire/bin/spire-server entry show -parentID spiffe://spiffe.cilium/ns/cilium-spire/sa/spire-agent
```

Now verify that the echo Pod has an Identity registered with the SPIRE server:

```
IDENTITY_ID=$(kubectl get cep -l app=echo -o=jsonpath='{.items[0].status.identity.id}')
echo $IDENTITY_ID
kubectl exec -n cilium-spire spire-server-0 -c spire-server -- /opt/spire/bin/spire-server entry show -spiffeID spiffe://spiffe.cilium/identity/$IDENTITY_ID
```

When you apply a mutual authentication policy, the agent retrieves the identity of the source Pod, connects to the node where the destination Pod is running and performs a mutual TLS handshake (with the log above showing one side of the mutual TLS handshake).

```
kubectl -n kube-system -c cilium-agent logs cilium-9pshw --timestamps=true | grep "Policy is requiring authentication\|Validating Server SNI\|Validated certificate\|Successfully authenticated"
```

## **Step 4: Shared Ingress (3 minutes)**
- Show how NGINX Ingress balances traffic across clusters using `nginx.ingress.kubernetes.io/service-upstream`.
- Simulate a pod failure in one cluster and demonstrate failover to the second cluster.

---

## **Step 5: Lightweight Service Mesh & Security (3 minutes)**
- Demonstrate Cilium’s service mesh-like functionality without sidecars.
- Show SPIRE/SPIFFE workload identity configuration.

---

## **Step 6: Node Encryption with Wireguard (2 minutes)**
- Show encrypted communication between nodes using Wireguard.

---


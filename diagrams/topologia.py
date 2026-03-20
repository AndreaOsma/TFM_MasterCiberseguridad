from diagrams import Diagram, Cluster, Edge
from diagrams.onprem.vcs import Gitea
from diagrams.onprem.security import Vault
from diagrams.onprem.database import Postgresql
from diagrams.onprem.compute import Server
from diagrams.onprem.iac import Terraform
from diagrams.k8s.compute import Pod

graph_attr = {
    "fontsize": "18",
    "fontname": "Helvetica-Bold",
    "pad": "0.5",
    "splines": "ortho",
    "nodesep": "0.8",
    "ranksep": "1.0",
    "bgcolor": "#FAFAFA"
}

node_attr = {
    "fontsize": "13",
    "fontname": "Helvetica"
}

edge_attr = {
    "fontsize": "11",
    "fontname": "Helvetica-Bold"
}

with Diagram("topologia", filename="topologia", show=False, direction="LR", graph_attr=graph_attr, node_attr=node_attr, edge_attr=edge_attr):
    
    with Cluster("Plano de Administración (CLI)", graph_attr={"bgcolor": "#E8F0FE"}):
        tf = Terraform("Terraform\n(Policy-as-Code)")

    with Cluster("Proxmox VE 9 (Hipervisor Tipo 1)", graph_attr={"bgcolor": "#FFFFFF"}):
        
        with Cluster("Zona Orquestación (VM)"):
            k3s = Server("K3s v1.28")
            workload = Pod("Carga de Trabajo")
            k3s - Edge(color="transparent") - workload
            
        with Cluster("Zona Servicios Core (LXC)"):
            gitea = Gitea("LXC 1: Gitea + Act Runner\n(CI/CD Pipeline)")
            vault = Vault("LXC 2: HashiCorp Vault\n(Bóveda Raft)")
            db = Postgresql("LXC 3: PostgreSQL v16\n(Target DB)")

    tf >> Edge(label="0. Aplica Políticas y Roles (HCL)", color="#555555", style="dashed") >> vault

    gitea >> Edge(label="1. Auth OIDC (Token JWT)", color="#1A73E8", penwidth="2.0") >> vault
    workload >> Edge(label="1b. Auth Service Account", color="#1A73E8", style="dotted") >> vault

    vault >> Edge(label="2. Crea Rol Temporal (TTL)", color="#0F9D58", penwidth="2.0") >> db
    vault >> Edge(label="3. Devuelve Credencial a Memoria", color="#0F9D58", style="dashed") >> gitea

    gitea >> Edge(label="4. Acceso Efímero (PostgreSQL)", color="#D93025", penwidth="2.0") >> db

from diagrams import Diagram, Cluster, Edge
from diagrams.onprem.vcs import Gitea
from diagrams.onprem.security import Vault
from diagrams.onprem.database import Postgresql
from diagrams.onprem.compute import Server
from diagrams.onprem.iac import Terraform
from diagrams.k8s.compute import Pod

graph_attr = {
    "fontsize": "20",
    "fontname": "Helvetica-Bold",
    "pad": "0.55",
    "splines": "ortho",
    "nodesep": "0.95",
    "ranksep": "1.1",
    "dpi": "240",
    "bgcolor": "#FAFAFA",
    "labelloc": "t",
    "labeljust": "c",
}

node_attr = {
    "fontsize": "12",
    "fontname": "Helvetica",
    "shape": "box",
    "style": "rounded,filled",
    "fillcolor": "#FFFFFF",
    "color": "#DADCE0",
}

edge_attr = {
    "fontsize": "10",
    "fontname": "Helvetica",
    "color": "#5F6368",
}

with Diagram(
    "Arquitectura del laboratorio y flujo de credenciales dinámicas",
    filename="diagrams/topologia",
    show=False,
    direction="LR",
    graph_attr=graph_attr,
    node_attr=node_attr,
    edge_attr=edge_attr,
):
    
    with Cluster(
        "Plano de Administración (CLI)",
        graph_attr={"bgcolor": "#E8F0FE", "style": "rounded", "color": "#AECBFA"},
    ):
        tf = Terraform("Terraform\n(Policy-as-Code)")

    with Cluster(
        "Proxmox VE 8.4 (Hipervisor Tipo 1)",
        graph_attr={"bgcolor": "#FFFFFF", "style": "rounded", "color": "#DADCE0"},
    ):
        
        with Cluster("Zona Orquestación (VM)"):
            k3s = Server("K3s v1.34.5+k3s1")
            workload = Pod("Carga de Trabajo")
            k3s - Edge(color="transparent") - workload
            
        with Cluster("Zona Servicios Core (LXC)"):
            gitea = Gitea("LXC 1: Gitea + Act Runner\n(CI/CD Pipeline)")
            vault = Vault("LXC 2: HashiCorp Vault\n(Bóveda Raft)")
            db = Postgresql("LXC 3: PostgreSQL v17\n(Target DB)")

    tf >> Edge(label="0. Aplica Políticas y Roles (HCL)", color="#555555", style="dashed") >> vault

    gitea >> Edge(label="1. Auth OIDC (Token JWT)", color="#1A73E8", penwidth="2.0") >> vault
    workload >> Edge(label="1b. Auth Service Account", color="#1A73E8", style="dotted") >> vault

    vault >> Edge(label="2. Crea Rol Temporal (TTL)", color="#0F9D58", penwidth="2.0") >> db
    vault >> Edge(label="3. Devuelve Credencial a Memoria", color="#0F9D58", style="dashed") >> gitea

    gitea >> Edge(label="4. Acceso Efímero (PostgreSQL)", color="#D93025", penwidth="2.0") >> db

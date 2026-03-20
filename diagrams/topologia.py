from diagrams import Diagram, Cluster, Edge
from diagrams.onprem.vcs import Gitea
from diagrams.onprem.security import Vault
from diagrams.onprem.database import Postgresql
from diagrams.onprem.compute import Server

graph_attr = {
    "fontsize": "14",
    "pad": "0.5"
}

with Diagram("Topología", show=False, direction="LR", graph_attr=graph_attr):
    
    with Cluster("Proxmox VE 9 (Hipervisor Tipo 1)"):
        
        with Cluster("Máquinas Virtuales"):
            k3s = Server("VM 1: K3s v1.28\n(Orquestación)")
            
        with Cluster("Contenedores Linux (LXC)"):
            gitea = Gitea("LXC 1: Gitea + Act Runner\n(CI/CD & Emisor OIDC)")
            vault = Vault("LXC 2: HashiCorp Vault\n(Bóveda Raft)")
            db = Postgresql("LXC 3: PostgreSQL v16\n(Target DB)")

    # Flujo de inyección dinámica de credenciales
    gitea >> Edge(label="1. Autenticación OIDC (JWT)", color="blue", style="bold") >> vault
    vault >> Edge(label="2. Crea Rol Efímero", color="darkgreen") >> db
    vault >> Edge(label="3. Inyecta Credencial en Memoria", color="darkgreen", style="dashed") >> gitea
    gitea >> Edge(label="4. Acceso temporal (TTL 300s)", color="red") >> db
    
    # Interacción de Kubernetes
    k3s >> Edge(label="Auth nativa (Service Accounts)", style="dotted") >> vault

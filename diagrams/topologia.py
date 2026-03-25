from diagrams import Diagram, Cluster, Edge
from diagrams.onprem.vcs import Gitea
from diagrams.onprem.security import Vault
from diagrams.onprem.database import Postgresql
from diagrams.onprem.compute import Server
from diagrams.onprem.iac import Terraform
from diagrams.k8s.compute import Pod

graph_attr = {
    # Estilo global para legibilidad en memoria y diapositivas.
    "fontsize": "22",
    "fontname": "Helvetica-Bold",
    "pad": "0.7",
    "splines": "spline",
    "nodesep": "1.05",
    "ranksep": "1.25",
    "dpi": "420",
    "bgcolor": "#FAFAFA",
    "labelloc": "t",
    "labeljust": "c",
}

node_attr = {
    # Nodos neutros para destacar los flujos por color de arista.
    "fontsize": "13",
    "fontname": "Helvetica",
    "shape": "box",
    "style": "rounded,filled",
    "fillcolor": "#FFFFFF",
    "color": "#DADCE0",
}

edge_attr = {
    # Tipografía compacta para etiquetas de flujo.
    "fontsize": "11",
    "fontname": "Helvetica",
    "color": "#5F6368",
}

with Diagram(
    "Topología del laboratorio (Proxmox + LXC) y flujo de credenciales dinámicas",
    filename="diagrams/topologia",
    outformat=["png", "svg"],
    show=False,
    direction="LR",
    graph_attr=graph_attr,
    node_attr=node_attr,
    edge_attr=edge_attr,
):
    
    with Cluster(
        "Administración (CLI) e IaC",
        graph_attr={"bgcolor": "#E8F0FE", "style": "rounded", "color": "#AECBFA"},
    ):
        tf = Terraform("Terraform\n(Policies + DB engine)")

    with Cluster(
        "Proxmox VE 8.4 (Hipervisor Tipo 1)",
        graph_attr={"bgcolor": "#FFFFFF", "style": "rounded", "color": "#DADCE0"},
    ):
        
        with Cluster("VM 1 (k3s) - orquestación"):
            k3s = Server("k3s v1.34.5+k3s1")
            workload = Pod("Carga de trabajo\n(opcional)")
            k3s - Edge(color="transparent") - workload
            
        with Cluster("LXC core (servicios)"):
            gitea = Gitea("LXC 1: Gitea + Act Runner\n(CI/CD)")
            vault = Vault("LXC 2: HashiCorp Vault\nRaft + DB secrets")
            db = Postgresql("LXC 3: PostgreSQL v17\n(Target DB)")

    # Flujo de secretos (verde/azul/rojo) ajustado al texto del TFM.
    tf >> Edge(
        label="Define políticas + motores\n(HCL)",
        color="#555555",
        style="dashed",
    ) >> vault

    # Flujo de autenticación y autorización hacia Vault.
    gitea >> Edge(
        label="Login con OIDC/JWT\n(Auth Vault)",
        color="#1A73E8",
        penwidth="2.0",
    ) >> vault

    # Emisión dinámica (TTL) y entrega de credencial efímera.
    vault >> Edge(
        label="Crea rol efímero TTL\n(database/creds/readonly-role)",
        color="#0F9D58",
        penwidth="2.0",
    ) >> db
    vault >> Edge(
        label="Devuelve credencial\n(lease)",
        color="#0F9D58",
        style="dashed",
    ) >> gitea

    # Uso temporal y revocación (DROP ROLE) en PostgreSQL.
    gitea >> Edge(
        label="Consulta temporal\n(SELECT read-only)",
        color="#D93025",
        penwidth="2.0",
    ) >> db
    vault >> Edge(
        label="Revoca lease => DROP ROLE",
        color="#D93025",
        style="dashed",
    ) >> db

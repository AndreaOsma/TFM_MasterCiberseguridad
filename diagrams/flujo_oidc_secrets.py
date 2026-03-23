from diagrams import Diagram, Cluster, Edge
from diagrams.onprem.vcs import Gitea
from diagrams.onprem.security import Vault
from diagrams.onprem.database import Postgresql
from diagrams.onprem.compute import Server

graph_attr = {
    "fontsize": "18",
    "fontname": "Helvetica-Bold",
    "pad": "0.35",
    "splines": "ortho",
    "nodesep": "1.0",
    "ranksep": "1.0",
    "dpi": "220",
    "bgcolor": "#FAFAFA",
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
    "flujo_oidc_secrets",
    filename="flujo_oidc_secrets",
    show=False,
    direction="LR",
    graph_attr=graph_attr,
    node_attr=node_attr,
    edge_attr=edge_attr,
):
    with Cluster(
        "Identidad y CI/CD",
        graph_attr={"bgcolor": "#E8F0FE", "style": "rounded", "color": "#AECBFA"},
    ):
        oidc = Server("OIDC Provider")
        runner = Gitea("Gitea + Act Runner")

    with Cluster(
        "Plano de Secretos",
        graph_attr={"bgcolor": "#FFFFFF", "style": "rounded", "color": "#DADCE0"},
    ):
        vault = Vault("Vault")
        postgres = Postgresql("PostgreSQL")

    runner >> Edge(label="1. Solicita token OIDC", color="#1A73E8", penwidth="2.0") >> oidc
    oidc >> Edge(label="2. Emite JWT firmado", color="#1A73E8", style="dashed") >> runner
    runner >> Edge(label="3. Login OIDC con JWT", color="#1A73E8", penwidth="2.0") >> vault
    vault >> Edge(label="4. Verifica JWT y policy", color="#5F6368", style="dashed") >> oidc
    vault >> Edge(label="5. Crea rol temporal (TTL)", color="#0F9D58", penwidth="2.0") >> postgres
    vault >> Edge(label="6. Entrega credenciales efimeras", color="#0F9D58", style="dashed") >> runner
    runner >> Edge(label="7. Acceso temporal a DB", color="#D93025", penwidth="2.0") >> postgres
    vault >> Edge(label="8. Revoca acceso (DROP ROLE)", color="#D93025", style="dashed") >> postgres

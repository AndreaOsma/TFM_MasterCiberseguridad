from diagrams import Diagram, Cluster, Edge
from diagrams.onprem.vcs import Gitea
from diagrams.onprem.security import Vault
from diagrams.onprem.database import Postgresql
from diagrams.onprem.compute import Server

graph_attr = {
    # Ajustes globales para lectura nítida en PDF y presentación.
    "fontsize": "20",
    "fontname": "Helvetica-Bold",
    "pad": "0.5",
    "splines": "ortho",
    "nodesep": "1.05",
    "ranksep": "1.1",
    "dpi": "240",
    "bgcolor": "#FAFAFA",
    "labelloc": "t",
    "labeljust": "c",
}

node_attr = {
    # Nodos claros y neutros; el significado principal va en las aristas.
    "fontsize": "12",
    "fontname": "Helvetica",
    "shape": "box",
    "style": "rounded,filled",
    "fillcolor": "#FFFFFF",
    "color": "#DADCE0",
}

edge_attr = {
    # Etiquetas compactas para mantener la secuencia legible.
    "fontsize": "10",
    "fontname": "Helvetica",
    "color": "#5F6368",
}

with Diagram(
    "Flujo OIDC para emisión y revocación de credenciales",
    filename="diagrams/flujo_oidc_secrets",
    outformat=["png", "svg"],
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

    # Flujo de federación de identidad (OIDC/JWT).
    runner >> Edge(label="1. Solicita token OIDC", color="#1A73E8", penwidth="2.0") >> oidc
    oidc >> Edge(label="2. Emite JWT firmado", color="#1A73E8", style="dashed") >> runner
    runner >> Edge(label="3. Login OIDC con JWT", color="#1A73E8", penwidth="2.0") >> vault
    vault >> Edge(label="4. Verifica JWT y policy", color="#5F6368", style="dashed") >> oidc
    # Flujo de emisión y consumo de credencial efímera.
    vault >> Edge(label="5. Crea rol temporal (TTL)", color="#0F9D58", penwidth="2.0") >> postgres
    vault >> Edge(label="6. Entrega credenciales efimeras", color="#0F9D58", style="dashed") >> runner
    runner >> Edge(label="7. Acceso temporal a DB", color="#D93025", penwidth="2.0") >> postgres
    # Cierre del ciclo de vida del secreto con revocación explícita.
    vault >> Edge(label="8. Revoca acceso (DROP ROLE)", color="#D93025", style="dashed") >> postgres

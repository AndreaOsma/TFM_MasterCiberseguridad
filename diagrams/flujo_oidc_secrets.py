from diagrams import Diagram, Cluster, Edge
from diagrams.onprem.vcs import Gitea
from diagrams.onprem.security import Vault
from diagrams.onprem.database import Postgresql
from diagrams.onprem.compute import Server

graph_attr = {
    # Ajustes globales para lectura nítida en PDF y presentación.
    "fontsize": "22",
    "fontname": "Helvetica-Bold",
    "pad": "0.65",
    "splines": "spline",
    "nodesep": "1.15",
    "ranksep": "1.25",
    "dpi": "420",
    "bgcolor": "#FAFAFA",
    "labelloc": "t",
    "labeljust": "c",
}

node_attr = {
    # Nodos claros y neutros; el significado principal va en las aristas.
    "fontsize": "13",
    "fontname": "Helvetica",
    "shape": "box",
    "style": "rounded,filled",
    "fillcolor": "#FFFFFF",
    "color": "#DADCE0",
}

edge_attr = {
    # Etiquetas compactas para mantener la secuencia legible.
    "fontsize": "11",
    "fontname": "Helvetica",
    "color": "#5F6368",
}

with Diagram(
    "Flujo OIDC (JWT) -> Vault -> PostgreSQL\nCredenciales TTL y revocación (DROP ROLE)",
    filename="diagrams/flujo_oidc_secrets",
    outformat=["png", "svg"],
    show=False,
    direction="LR",
    graph_attr=graph_attr,
    node_attr=node_attr,
    edge_attr=edge_attr,
):
    with Cluster(
        "CI/CD (Runner) y Proveedor OIDC",
        graph_attr={"bgcolor": "#E8F0FE", "style": "rounded", "color": "#AECBFA"},
    ):
        oidc = Server("Proveedor OIDC")
        runner = Gitea("Gitea + Act Runner\n(pipeline)")

    with Cluster(
        "Vault y Motor de Base de Datos",
        graph_attr={"bgcolor": "#FFFFFF", "style": "rounded", "color": "#DADCE0"},
    ):
        vault = Vault("Vault\n(auth + database secrets)")
        postgres = Postgresql("PostgreSQL v17\n(sistema objetivo)")

    # Flujo federado (OIDC/JWT) + emisión dinámica (TTL) y revocación.
    runner >> Edge(label="1) Solicita token OIDC", color="#1A73E8", penwidth="2.0") >> oidc
    oidc >> Edge(label="2) JWT firmado\n(credencial efímera de identidad)", color="#1A73E8", style="dashed") >> runner
    runner >> Edge(
        label="3) Login Vault con JWT\n(valida firma + policy)",
        color="#1A73E8",
        penwidth="2.0",
    ) >> vault

    vault >> Edge(
        label="4) Genera rol efímero TTL\n(database/creds/readonly-role)",
        color="#0F9D58",
        penwidth="2.0",
    ) >> postgres
    vault >> Edge(
        label="5) Devuelve credencial\n(lease con TTL)",
        color="#0F9D58",
        style="dashed",
    ) >> runner
    runner >> Edge(
        label="6) Consulta temporal\n(SELECT read-only)",
        color="#D93025",
        penwidth="2.0",
    ) >> postgres
    vault >> Edge(
        label="7) Revoca lease => DROP ROLE",
        color="#D93025",
        style="dashed",
    ) >> postgres

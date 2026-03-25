from diagrams import Diagram, Cluster, Edge
from diagrams.onprem.compute import Server

graph_attr = {
    # Estilo homogéneo con el resto de diagramas del TFM.
    "fontsize": "22",
    "fontname": "Helvetica-Bold",
    "pad": "0.7",
    "splines": "spline",
    "nodesep": "1.25",
    "ranksep": "1.35",
    "dpi": "420",
    "bgcolor": "#FAFAFA",
    "labelloc": "t",
    "labeljust": "c",
}

node_attr = {
    # Tamaño de nodo algo menor para acomodar más texto por bloque.
    "fontsize": "11.5",
    "fontname": "Helvetica",
    "shape": "box",
    "style": "rounded,filled",
    "fillcolor": "#FFFFFF",
    "color": "#DADCE0",
}

edge_attr = {
    # Etiquetas breves para no saturar la matriz.
    "fontsize": "10",
    "fontname": "Helvetica",
    "color": "#5F6368",
}

with Diagram(
    "Matriz de trazabilidad normativa, técnica y evidencial",
    filename="diagrams/matriz_trazabilidad",
    outformat=["png", "svg"],
    show=False,
    direction="LR",
    graph_attr=graph_attr,
    node_attr=node_attr,
    edge_attr=edge_attr,
):
    with Cluster(
        "Requisito Normativo",
        graph_attr={"bgcolor": "#E8F0FE", "style": "rounded", "color": "#AECBFA"},
    ):
        req_zt = Server("NIST SP 800-207\nZero Trust")
        req_nis2 = Server("NIS2\nGestión de riesgos")
        req_dora = Server("DORA\nResiliencia operativa")

    with Cluster(
        "Control Implementado",
        graph_attr={"bgcolor": "#FFFFFF", "style": "rounded", "color": "#DADCE0"},
    ):
        ctrl_oidc = Server("Autenticación federada\nOIDC + JWT")
        ctrl_ttl = Server("Credenciales efímeras\nTTL + DROP ROLE")
        ctrl_audit = Server("Auditoría Vault\nEventos JSON")
        ctrl_iac = Server("IaC (Terraform)\nPolíticas versionadas")

    with Cluster(
        "Evidencia en el TFM",
        graph_attr={"bgcolor": "#F1F8E9", "style": "rounded", "color": "#B7E1CD"},
    ):
        ev_flow = Server("Fig. Flujo OIDC\n(fig:flujo-oidc-secrets)")
        ev_topo = Server("Fig. Topología\n(fig:topologia)")
        ev_listings = Server("Listados IaC\n(lst:setup, lst:terraform-main)")
        ev_results = Server("Sección Resultados\n(TTL + auditoría)")

    # Mapeo norma -> control técnico implementado.
    req_zt >> Edge(label="Acceso dinámico", color="#1A73E8", penwidth="1.8") >> ctrl_oidc
    req_zt >> Edge(label="Menor exposición", color="#1A73E8", penwidth="1.8") >> ctrl_ttl

    req_nis2 >> Edge(label="Trazabilidad", color="#1A73E8", penwidth="1.8") >> ctrl_audit
    req_nis2 >> Edge(label="Control técnico", color="#1A73E8", penwidth="1.8") >> ctrl_iac

    req_dora >> Edge(label="Resiliencia", color="#1A73E8", penwidth="1.8") >> ctrl_iac
    req_dora >> Edge(label="Eventos auditables", color="#1A73E8", penwidth="1.8") >> ctrl_audit

    # Mapeo control -> evidencia concreta dentro de la memoria.
    ctrl_oidc >> Edge(label="Evidencia", color="#0F9D58", penwidth="1.8") >> ev_flow
    ctrl_ttl >> Edge(label="Evidencia", color="#0F9D58", penwidth="1.8") >> ev_results
    ctrl_audit >> Edge(label="Evidencia", color="#0F9D58", penwidth="1.8") >> ev_topo
    ctrl_iac >> Edge(label="Evidencia", color="#0F9D58", penwidth="1.8") >> ev_listings

from diagrams import Diagram, Cluster, Edge
from diagrams.onprem.compute import Server

graph_attr = {
    "fontsize": "20",
    "fontname": "Helvetica-Bold",
    "pad": "0.5",
    "splines": "ortho",
    "nodesep": "1.15",
    "ranksep": "1.15",
    "dpi": "240",
    "bgcolor": "#FAFAFA",
    "labelloc": "t",
    "labeljust": "c",
}

node_attr = {
    "fontsize": "10.5",
    "fontname": "Helvetica",
    "shape": "box",
    "style": "rounded,filled",
    "fillcolor": "#FFFFFF",
    "color": "#DADCE0",
}

edge_attr = {
    "fontsize": "9.5",
    "fontname": "Helvetica",
    "color": "#5F6368",
}

with Diagram(
    "Matriz de trazabilidad normativa, técnica y evidencial",
    filename="diagrams/matriz_trazabilidad",
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
        req_dora = Server("DORA\nResiliencia operacional")

    with Cluster(
        "Control Implementado",
        graph_attr={"bgcolor": "#FFFFFF", "style": "rounded", "color": "#DADCE0"},
    ):
        ctrl_oidc = Server("OIDC + JWT\nAuth federada")
        ctrl_ttl = Server("Credenciales efímeras\nTTL + DROP ROLE")
        ctrl_audit = Server("Auditoría Vault\nEventos JSON")
        ctrl_iac = Server("IaC (Terraform)\nPolíticas versionadas")

    with Cluster(
        "Evidencia en el TFM",
        graph_attr={"bgcolor": "#F1F8E9", "style": "rounded", "color": "#B7E1CD"},
    ):
        ev_flow = Server("Figura: Flujo OIDC\n(fig:flujo-oidc-secrets)")
        ev_topo = Server("Figura: Topología\n(fig:topologia)")
        ev_listings = Server("Listados Terraform/Setup\n(lst:terraform-main, lst:setup)")
        ev_results = Server("Resultados y Discusión\n(Secciones 6 y 7)")

    req_zt >> Edge(label="Autenticación continua", color="#1A73E8", penwidth="1.8") >> ctrl_oidc
    req_zt >> Edge(label="Menor exposición", color="#1A73E8", penwidth="1.8") >> ctrl_ttl

    req_nis2 >> Edge(label="Riesgo y trazabilidad", color="#1A73E8", penwidth="1.8") >> ctrl_audit
    req_nis2 >> Edge(label="Control técnico", color="#1A73E8", penwidth="1.8") >> ctrl_iac

    req_dora >> Edge(label="Resiliencia operativa", color="#1A73E8", penwidth="1.8") >> ctrl_iac
    req_dora >> Edge(label="Trazas auditables", color="#1A73E8", penwidth="1.8") >> ctrl_audit

    ctrl_oidc >> Edge(label="Evidencia en flujo", color="#0F9D58", penwidth="1.8") >> ev_flow
    ctrl_ttl >> Edge(label="Evidencia en resultados", color="#0F9D58", penwidth="1.8") >> ev_results
    ctrl_audit >> Edge(label="Evidencia en topología/resultados", color="#0F9D58", penwidth="1.8") >> ev_topo
    ctrl_iac >> Edge(label="Evidencia en listados", color="#0F9D58", penwidth="1.8") >> ev_listings

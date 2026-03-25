# Guion oral de defensa (12-15 min)

## Apertura (0:00-1:00)
- Problema: el Secret Sprawl multiplica superficie de ataque en CI/CD.
- Pregunta: si usamos identidad federada y credenciales efimeras, ¿se reduce de forma medible la ventana de exposicion?
- Tesis: eliminar secretos persistentes y pasar a emision dinamica con politicas y revocacion.

## Contexto minimo (1:00-2:30)
- Referencias de control: Zero Trust (NIST SP 800-207), NIS2 y DORA.
- Cambio de paradigma: del perimetro a la identidad como plano de control.

## Arquitectura y metodo (2:30-6:00)
- Arquitectura en 3 planos: autenticacion, autorizacion, emision dinamica.
- Laboratorio on-premise reproducible (Proxmox + Gitea/Runner + Vault + PostgreSQL + k3s).
- Falsabilidad del experimento con tres aserciones:
  - A: TTL acotado.
  - B: revocacion efectiva y eliminacion del rol.
  - C: denegacion a identidad sin politica.

## Evidencia empirica (6:00-10:30)
- Demo en vivo: `video_demo_run.sh` para veredicto inmediato.
- Campana repetida: `validation_campaign.sh` para estabilidad de resultados.
- Mensaje clave: no es una prueba unica, es evidencia repetible con salida estructurada.

## Discusion y limites (10:30-12:00)
- Resultado: mitigacion efectiva del uso de credenciales persistentes.
- Limites: falta campana extensa de resiliencia y analisis estadistico mas profundo.
- Riesgo residual: dependencia de componentes externos (IdP, red, disponibilidad de Vault).

## Cierre (12:00-13:00)
- Contribucion: integra seguridad operativa + trazabilidad + reproducibilidad.
- Impacto: reduce tiempo util de abuso y mejora capacidad de auditoria.
- Siguiente paso: SIEM operativo, fallos controlados y extension a otros secretos.

## Preguntas esperables del tribunal (respuestas cortas)
- **Escalabilidad:** pasar a Vault HA y separar planos de control/datos.
- **Generalizacion:** patron aplicable a certificados/API keys con el mismo ciclo TTL+revocacion.
- **Coste operativo:** mayor complejidad inicial, menor riesgo y menor deuda de secretos a medio plazo.
- **Validez externa:** se mejora replicando en otro entorno y comparando distribuciones de metricas.

# Lo que aprendí en el TFM: pasar de secretos fijos a accesos que caducan

Voy al grano: empecé este TFM porque me cansé de ver lo mismo en muchos entornos técnicos.  
Tokens en variables de entorno, contraseñas en scripts “temporales”, llaves que se crean un día y ahí se quedan para siempre.

No es mala intención. Casi siempre es prisa.

El problema es que esa prisa deja huella. Y esa huella, en seguridad, se llama *Secret Sprawl*: secretos repartidos por todas partes, difíciles de controlar y todavía más difíciles de rotar bien.

## La pregunta que me hice

La pregunta fue muy simple:

**¿se puede reducir este riesgo sin destrozar la operativa del equipo?**

Porque una solución de seguridad que ralentiza CI/CD o obliga a hacer malabares cada vez que despliegas, en la práctica, no dura.

## La idea central (en lenguaje humano)

En vez de “guardar una credencial y reutilizarla”, probé otro enfoque:

- el pipeline se autentica con identidad federada (OIDC),
- Vault comprueba esa identidad y la política,
- genera credenciales efímeras con TTL,
- cuando acaba el trabajo, ese acceso se revoca.

¿Qué cambia aquí? Que si algo se filtra, ya no tienes una llave válida durante semanas o meses. Tienes un acceso que se muere solo.

Dicho de otra forma: dejo de confiar en “un secreto bien guardado” y paso a confiar en identidad + contexto + caducidad.

## Cómo lo llevé al laboratorio

Monté todo en Proxmox, con componentes muy reconocibles:

- Gitea + runner para CI/CD,
- Vault para gestión de secretos,
- PostgreSQL como destino,
- k3s para el entorno de ejecución.

Y lo más importante para mí: todo definido como código (Terraform + scripts).  
Quería que el entorno fuese repetible, no una demo que solo funciona “en mi portátil”.

Aquí aprendí algo importante: levantar el laboratorio fue la parte fácil; lo difícil fue ajustar políticas y flujos para que fueran seguros sin romper la experiencia de uso del pipeline.

## Los dos diagramas que mejor explican el trabajo

### Matriz de trazabilidad normativa

Este diagrama lo hice porque no quería quedarme en “esto cumple”.
Quería enseñar el hilo completo: requisito normativo -> control técnico -> evidencia en el TFM.

![Matriz de trazabilidad normativa](../../diagrams/matriz_trazabilidad.png)

### Flujo OIDC -> Vault -> PostgreSQL

Aquí está el corazón técnico del proyecto: autenticación federada, emisión temporal y revocación automática.

![Flujo de autenticación OIDC y secretos dinámicos](../../diagrams/flujo_oidc_secrets.png)

## Qué resultados me parecieron más valiosos

Lo que vi en laboratorio fue consistente:

- la emisión dinámica funciona,
- la revocación también,
- y la traza de auditoría sirve para investigar lo que pasa.

Además, al estar todo versionado, repetir el despliegue no depende de memoria ni de “pasos mágicos”.

Si tengo que elegir una decisión que más impacto tuvo, fue priorizar la revocación automática. Es lo que realmente corta la persistencia del riesgo cuando algo sale mal.

No es una bala de plata. Pero sí un salto claro respecto a credenciales estáticas repartidas por medio sistema.

## Lo que no quiero vender como perfecto

Tiene límites, y prefiero decirlos claramente:

- está validado en un laboratorio concreto,
- falta ampliar la parte cuantitativa (latencias, escenarios de fallo, comparativas más amplias),
- y queda el paso de integrar correlación real en SIEM en contexto operativo.

Aun así, la base técnica es sólida y, sobre todo, útil.

Si repitiera el TFM desde cero, metería antes la parte de métricas. A nivel técnico, el diseño funciona; pero para convencer rápido a perfiles no técnicos, los números ayudan mucho.

## Si tuviera que resumirlo en una línea

**Menos secretos permanentes. Más identidad verificable. Accesos que caducan solos.**

Y eso, además de mejorar seguridad, ayuda mucho cuando toca demostrar control ante auditoría y cumplimiento.

# 🛡️ SafeGrid Local V3 - Checklist de Defensa Académica

Este documento está diseñado para ayudarte a defender el proyecto "SafeGrid Local" como una plataforma SOC (Security Operations Center) completa.

## 1. De Detección a Respuesta Activa (NIST Cybersecurity Framework)
**Pregunta:** *¿Cómo aborda tu sistema los lineamientos del NIST?*
**Respuesta:** El NIST CSF se basa en 5 pilares: Identificar, Proteger, Detectar, Responder y Recuperar. 
SafeGrid V3 completó el ciclo integrando las fases de **Respuesta y Recuperación**. Ahora los operadores pueden intervenir activamente en la propagación de malware mediante acciones como aislar (Isolate) PLCs de la red OT, mitigando el impacto físico antes de que la degradación en cascada ocurra.

## 2. Microsegmentación Lógica y Aislamiento de Dispositivos
**Pregunta:** *¿Qué pasa cuando aislo un dispositivo en tu interfaz?*
**Respuesta:** Cuando un operador (con rol autorizado) hace click en "Isolate" sobre el Network Map, el backend actualiza la bandera `isIsolated = true` en la base de datos para simular una regla de firewall en el Switch del puerto (`Port Security` o `VLAN Isolation`). 
El algoritmo de Ransomware de SafeGrid chequea este estado en tiempo real. Si el PLC está aislado, el malware interrumpe su ciclo de infección horizontal impidiendo el movimiento lateral hacia otros controladores industriales.

## 3. Explanability e Inteligencia de Causa Raíz (Root Cause Analysis)
**Pregunta:** *¿Cómo sabe el operador por qué cayó el sistema de agua?*
**Respuesta:** En entornos OT, explicar el impacto cibernético a los ingenieros de planta es difícil. Integré un motor de **Explicabilidad (Explanability)**. Cuando el motor detecta una falla en cascada (Ransomware -> Energía cae -> Agua y Textil caen por falta de suministro), computa un árbol de dependencias y escribe en lenguaje natural la causa raíz exacta (*"Why did this happen?"*) dentro de la pestaña del Incidente.

## 4. Recuperación Controlada
**Pregunta:** *¿Cómo vuelve el sistema a la normalidad?*
**Respuesta:** Una vez los dispositivos infectados son aislados, el operador en la pestaña "Incidents" declara el incidente como "CONTENIDO" (Contain Incident). Posteriormente, los equipos de mantenimiento físico purgan los PLCs, permitiendo que el operador presione "Recover System" en la interfaz. El motor levanta de nuevo el *Grid* de Energía, Agua y Textil a estado Operacional.

---
**🔥 Cierre de Ingeniería SOC (Para el 10 y uso en PORTAFOLIO TÉCNICO):**
Durante tu defensa, usa esta coreografía:
1. Inicia sesión como `admin`.
2. Lanza el ataque de Ransomware. 
3. Inmediatamente vete a "Network Map" y **Aisla (Isolate)** el segundo y tercer PLC. 
4. Demuestra que solo el primero se infectó (porque actuaste rápido). 
5. Ve a "Incidents" y clickea **Contain Incident**. Muestra el "Root Cause Analysis" (Explicación).
6. Ve a "Infrastructure" y clickea **Recover System** para restaurar la normalidad.
*(Has demostrado una simulación completa de Kill-Chain y Mitigación de Sistemas Críticos en Tiempo Real. Nivel Experto).*

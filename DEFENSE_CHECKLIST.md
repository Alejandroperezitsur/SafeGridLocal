# 🛡️ SafeGrid Local - Checklist de Defensa Académica

Este documento está diseñado para ayudarte a defender el proyecto "SafeGrid Local" frente a tus profesores o evaluadores, justificando las decisiones de arquitectura, ciberseguridad y desarrollo.

## 1. Arquitectura del Sistema (IT/OT)
**Pregunta:** *¿Cómo está construida la aplicación y por qué?*
**Respuesta:**
- **Frontend (Flutter):** Elegido por su rendimiento y compilación nativa. Permite desplegar el "Centro de Control" en Desktop (Windows), Web o Móvil desde la misma base de código. Se usó el patrón **MVVM** junto con **Riverpod** para tener *Separation of Concerns*: la UI reacciona a los cambios en los proveedores de estado sin acoplarse a la lógica de red.
- **Backend (Node.js + Express + SQLite):** Se diseñó bajo filosofía *Offline-first / Local Network*. En un entorno industrial (OT), los sistemas de monitoreo no deben depender de la nube pública (internet). SQLite almacena la simulación localmente, lo cual es rápido, transaccional y sobrevive reinicios.

## 2. Segmentación de Red y Modelo Purdue (ISA/IEC 62443)
**Pregunta:** *¿Cómo modelaste la red y qué es el modelo Purdue?*
**Respuesta:**
- El **Modelo Purdue** es un marco de referencia de arquitectura de seguridad para sistemas de control industrial (ICS).
- En SafeGrid, dividimos los dispositivos en 3 zonas (ver `NetworkMapScreen`):
  1. **Nivel 4/5 (IT Zone):** Red corporativa, routers, PCs de empleados.
  2. **Nivel 3.5 (DMZ):** Zona desmilitarizada, servidores SCADA. Aisla el IT del OT.
  3. **Niveles 1/2/3 (OT Zone):** PLCs y máquinas de producción (Agua, Energía, Textil).
- **Justificación:** Si un atacante compromete un PC corporativo, la segmentación (VLANs/Firewalls) impide llegar directamente a los PLCs.

## 3. Motor de Detección de Amenazas (IDS/IPS Simulado)
**Pregunta:** *¿Cómo funciona su lógica de detección?*
**Respuesta:**
- En `threatEngine.js`, implementamos reglas basadas en firma y comportamiento:
  - **Fuerza Bruta:** Si un usuario (`login_attempts`) supera los 5 fallos, se alerta como Criticidad Alta.
  - **Identidad de Dispositivo:** Dispositivos insertados sin la bandera de confianza (`isTrusted = false`) levantan alerta técnica (Medium).
  - **Horario Fuera de Rango:** Acceso en la madrugada asume compromiso de credenciales.
- Se inspira en estándares del NIST SP 800-82 para protección de OT.

## 4. Defensa en Profundidad (Defense in Depth) y Risk Score
**Pregunta:** *¿Por qué el simulacro apaga sistemas específicos y cómo se mide el riesgo?*
**Respuesta:**
- **Propagación:** La función `simulateAttack` emula un Ransomware dirigido a la red OT. Al comprometer los PLCs, observamos la caída en cascada de los Sistemas Críticos (Ej. La Producción Textil depende del Agua y Energía).
- **Risk Score:** Se calcula dinámicamente (`Alto * 3 + Medio * 2 + Bajo * 1`). Esto traduce logotipos técnicos complejos a una interfaz ejecutiva de semáforo verde-amarillo-rojo, demostrando alineación negocio-seguridad.

## 5. Pruebas y Validación OBLIGATORIA
- [x] **Conexión desconocida:** Se probó inyectando un dispositivo (`isTrusted: 0`) y la alerta aparece.
- [x] **Intentos fallidos:** El test simula 6 intentos y registra correctamente "Brute Force".
- [x] **Ataque:** El botón rojo (Ransomware) tumba los sistemas de Agua/Textil y el dashboard explota en nivel de Riesgo Alto (>16 puntos).
- [x] **Controles de Acceso (IAM):** La API (`/api/simulate`) rechaza ejecuciones si el usuario no es `admin`.

---
**Tip final para el 10:** ¡Abre la app, entra como `admin/admin123` y muestra la pantalla del Mapa de Red al mismo tiempo que la simulación de ataque. El cambio visual instantáneo validará tu trabajo técnico!

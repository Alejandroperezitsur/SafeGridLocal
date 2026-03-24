# 🛡️ SafeGrid Local V2 - Checklist de Defensa Académica

Este documento está diseñado para ayudarte a defender el proyecto "SafeGrid Local" como una simulación profesional ante tus profesores o evaluadores. 

## 1. De Alertas a Inteligencia de Incidentes (V2)
**Pregunta:** *¿Por qué un Motor de Incidentes en lugar de Alertas Simples?*
**Respuesta:** En SOCs (Security Operations Centers) reales, la fatiga de alertas es el peor enemigo. Este motor realiza **Correlación de Eventos**. Por ejemplo, si el sistema detecta "Logins Fallidos" y luego un "Dispositivo Desconocido", el motor no escupe 2 alertas aisladas, sino que consolida la información en un **Incidente de Intrusión (Intrusion Attempt)** activo, y comienza a graficar una línea de tiempo para entender tácticas, técnicas y procedimientos (TTPs).

## 2. Segmentación de Red y Modelo Purdue (ISA/IEC 62443)
**Pregunta:** *¿Cómo modelaste la red y qué es el modelo Purdue?*
**Respuesta:** Dividimos la arquitectura en 3 zonas: IT (Nivel 4/5), DMZ (Nivel 3.5) y OT (Niveles 1/2/3). Las mitigaciones en un modelo Purdue asumen que si un PC corporativo (IT) es comprometido, los servidores de DMZ previenen la infección directa a los PLC (OT).

## 3. Simulación de Impacto Real en Cascada
**Pregunta:** *¿Cómo modelaste el impacto en la infraestructura?*
**Respuesta:** La aplicación utiliza dependencias cruzadas reales (ej. La Planta Tratadora de Agua requiere energía para operar. La Producción Textil requiere de ambas). 
Cuando lanzamos el simulador de Ransomware, el motor `threatEngine` implementa un algoritmo de propagación temporal (con *delays*) que infecta dispositivos vecinos en la red OT. Al caer los controladores de Energía, su estatus cambia a "DOWN", lo que tira en cascada el sistema de Agua y finalmente detiene la Producción Textil, reflejando apagones reales como el ocurrido en *Colonial Pipeline*.

## 4. Defensa en Profundidad y Cálculo de Riesgo (Risk Score)
**Pregunta:** *¿Cómo funciona su indicador de impacto?*
**Respuesta:** Evaluamos el riesgo no solo por la cantidad de vulnerabilidades, sino por los incidentes activos.
Risk Score = (Incidentes Críticos * 50) + (Incidentes Altos * 20) + Alertas Simples.
Esto permite que el *Control Center* pase de verde a mostrar un **CRITICAL IMPACT** automáticamente si hay ransomware diseminándose, acortando el tiempo de respuesta (MTTD).

---
**🔥 Cierre de Ingeniería (Para el 10 Perfecto):**
Durante tu defensa, presiona el botón "Simulate Ransomware" (iniciando sesión como `admin/admin123`) e invita a los sinodales a observar la pestaña **Incident Timeline**. Verán cómo los eventos se agregan en tiempo real uno a uno (con segundos de diferencia) demostrando la propagación progresiva del malware, mientras en la pestaña **Infrastructure** los sistemas se degradan en cascada.
*(Es un simulador OT profesional, no un simple CRUD de base de datos).*

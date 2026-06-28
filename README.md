<p align="center">
  <img src="logo.png" alt="SafeGrid Local Logo" width="120"/>
</p>

<h1 align="center">SafeGrid Local</h1>

<p align="center">
  <strong>Simulador SOC para Infraestructuras Críticas IT/OT</strong><br/>
  <em>Plataforma educativa y operativa de ciberseguridad industrial</em>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter" alt="Flutter"/>
  <img src="https://img.shields.io/badge/Node.js-20.x-339933?logo=node.js" alt="Node.js"/>
  <img src="https://img.shields.io/badge/SQLite-3-003B57?logo=sqlite" alt="SQLite"/>
  <img src="https://img.shields.io/badge/NIST_CSF-Compliant-blue" alt="NIST"/>
  <img src="https://img.shields.io/badge/Licencia-MIT-green" alt="License"/>
</p>

---

## Descripción General

**SafeGrid Local** es un simulador avanzado de centro de operaciones de seguridad (SOC) diseñado para visualizar, detectar y mitigar ciberataques en infraestructuras críticas industriales. La plataforma modela la propagación de ransomware desde redes corporativas (IT) hasta sistemas de control industrial (OT), permitiendo a los operadores practicar la respuesta a incidentes en un entorno seguro.

El sistema está diseñado bajo el marco **NIST Cybersecurity Framework** y cubre las cinco fases del ciclo de seguridad: **Identificar, Proteger, Detectar, Responder y Recuperar**.

### Problema que Resuelve

En entornos industriales reales, un ciberataque puede provocar daños físicos en plantas de agua, redes eléctricas o producción textil. SafeGrid Local permite a los estudiantes y profesionales de seguridad experimentar esta cadena de ataque (Kill Chain) y practicar las acciones SOC necesarias para contenerla, sin riesgo real.

---

## Características Principales

| Característica | Descripción |
|---|---|
| **Dashboard de Riesgo** | Visualización en tiempo real del Risk Score del sistema con animaciones dinámicas según el nivel de amenaza |
| **Mapa de Red (Modelo Purdue)** | Clasificación de dispositivos en capas IT, DMZ y OT para visualizar segmentación y propagación de amenazas |
| **Motor de Simulación** | Propagación de ransomware con retardo realista (4s por dispositivo) que permite respuesta humana |
| **Aislamiento de Dispositivos** | Desconexión lógica de PLCs comprometidos simulando reglas de firewall / VLAN isolation |
| **Contención de Incidentes** | Marcado de incidentes como contenidos siguiendo procedimientos NIST/ISA |
| **Recuperación de Sistemas** | Restauración de sistemas críticos (Energía, Agua, Textil) a estado operativo |
| **Explicabilidad (Root Cause Analysis)** | Motor que genera explicaciones en lenguaje natural de por qué un sistema colapsó en cascada |
| **Educación Integrada** | Analogías simples, guías paso a paso y tutoriales en pantalla para usuarios no técnicos |
| **Demo Mode** | Funciona sin backend en GitHub Pages con datos mock para demostraciones |
| **Multiplataforma** | Disponible para Web, Windows, macOS, Linux, Android e iOS |

---

## Arquitectura del Sistema

```
┌─────────────────────────────────────────────────────────┐
│                   SAFEGRID LOCAL                        │
├──────────────────────┬──────────────────────────────────┤
│                      │                                  │
│   ┌──────────────┐   │   ┌──────────────────────────┐   │
│   │  Flutter App │◄──┼──►│   Node.js + Express API  │   │
│   │  (Frontend)  │   │   │      (Backend)           │   │
│   │              │   │   │                          │   │
│   │  - Dashboard │   │   │  - Threat Engine         │   │
│   │  - Net Map   │   │   │  - Correlation Engine    │   │
│   │  - Incidents │   │   │  - Cascade Evaluator     │   │
│   │  - Infra     │   │   │  - Response Actions      │   │
│   └──────────────┘   │   └──────────┬───────────────┘   │
│                      │              │                   │
│   Riverpod (State)   │   ┌──────────▼───────────────┐   │
│   Dio (HTTP)         │   │      SQLite Database     │   │
│   GoRouter (Routes)  │   │  users, devices, events, │   │
│   fl_chart (Charts)  │   │  incidents, systems      │   │
│                      │   └──────────────────────────┘   │
└──────────────────────┴──────────────────────────────────┘
```

### Flujo de Datos

1. El **Frontend** realiza peticiones HTTP al Backend vía `ApiClient` (Dio).
2. El **Backend** procesa las solicitudes y ejecuta la lógica del **Threat Engine**.
3. El **Threat Engine** genera eventos de seguridad, crea incidentes y evalúa correlaciones.
4. Los datos persisten en **SQLite** y se devuelven al Frontend en formato JSON.
5. El Frontend actualiza el estado mediante **Riverpod** y refresca la UI automáticamente cada 2 segundos.

---

## Tecnologías Utilizadas

### Frontend (`safegrid_app`)

| Paquete | Versión | Propósito |
|---|---|---|
| Flutter | SDK ^3.6.0 | Framework multiplataforma |
| flutter_riverpod | ^2.6.1 | Gestión de estado reactiva |
| dio | ^5.9.2 | Cliente HTTP |
| go_router | ^16.1.0 | Navegación y rutas |
| fl_chart | ^0.71.0 | Gráficas de datos |
| shared_preferences | ^2.5.3 | Persistencia local ligera |
| google_fonts | ^6.2.1 | Tipografías personalizadas |
| animate_do | ^3.3.4 | Animaciones de entrada |

### Backend (`safegrid_backend`)

| Paquete | Versión | Propósito |
|---|---|---|
| express | ^5.2.1 | Framework web |
| sqlite3 | ^6.0.1 | Base de datos relacional |
| cors | ^2.8.6 | Habilitar CORS |
| dotenv | ^17.3.1 | Variables de entorno |
| jsonwebtoken | ^9.0.3 | Autenticación JWT |

---

## Estructura del Proyecto

```
SafeGridLocal-main/
├── README.md                          # Este archivo
├── DEFENSE_CHECKLIST.md               # Guía de defensa académica
├── logo.png                           # Identidad visual de SafeGrid
│
├── safegrid_app/                      # Frontend Flutter
│   ├── lib/
│   │   ├── main.dart                  # Punto de entrada y routing
│   │   ├── core/
│   │   │   ├── api_client.dart        # Cliente HTTP configurable
│   │   │   └── theme.dart             # Sistema de diseño Cyberpunk
│   │   ├── models/
│   │   │   └── models.dart            # Modelos: User, Device, Incident, etc.
│   │   ├── repositories/
│   │   │   └── repositories.dart      # Data + Auth repositories (con Demo Mode)
│   │   ├── viewmodels/
│   │   │   └── providers.dart         # Riverpod providers y lógica de estado
│   │   └── views/
│   │       ├── login_screen.dart      # Pantalla de autenticación
│   │       ├── dashboard_screen.dart  # Centro de comando principal
│   │       ├── network_map_screen.dart # Mapa de red tipo Purdue
│   │       ├── incidents_screen.dart  # Sala SOC - gestión de incidentes
│   │       ├── critical_infra_screen.dart # Control de planta
│   │       ├── alerts_screen.dart     # Centro de alertas
│   │       ├── educational_screen.dart # Contenido educativo
│   │       └── widgets/
│   │           ├── educational_widgets.dart
│   │           ├── onboarding_data.dart
│   │           └── screen_onboarding.dart
│   ├── assets/
│   │   └── logo.png
│   ├── android/                       # Configuración Android
│   ├── ios/                           # Configuración iOS
│   ├── web/                           # Configuración Web
│   ├── windows/                       # Configuración Windows
│   ├── linux/                         # Configuración Linux
│   ├── macos/                         # Configuración macOS
│   └── pubspec.yaml                   # Dependencias Flutter
│
├── safegrid_backend/                  # Backend Node.js
│   ├── index.js                       # Servidor Express y rutas API
│   ├── db.js                          # Conexión SQLite y seeds iniciales
│   ├── threatEngine.js                # Motor de amenazas y respuesta SOC
│   ├── database.sqlite                # Base de datos persistente
│   ├── package.json                   # Dependencias Node.js
│   ├── test.js                        # Tests básicos
│   └── test_v3.js                     # Tests de la versión 3
│
└── Infraestructuras Críticas e Industriales.txt  # Documentación de referencia
```

---

## Requisitos Previos

- **Node.js** >= 18.x
- **npm** >= 9.x
- **Flutter SDK** >= 3.6.0
- **Chrome** (para ejecución web) o emulador móvil

---

## Instalación y Configuración

### 1. Clonar el Repositorio

```bash
git clone https://github.com/usuario/SafeGridLocal-main.git
cd SafeGridLocal-main
```

### 2. Iniciar el Backend

```bash
cd safegrid_backend
npm install
node index.js
```

El servidor arrancará en `http://localhost:3000` y se escuchará en todas las interfaces de red.

> **Nota:** La base de datos se crea automáticamente con datos iniciales (usuarios, dispositivos, sistemas críticos). Si ejecutas el servidor por segunda vez, el estado se reinicia automáticamente.

### 3. Iniciar el Frontend

```bash
cd safegrid_app
flutter pub get
flutter run -d chrome
```

Para ejecutar en otras plataformas:
```bash
flutter run -d windows    # Windows
flutter run -d macos      # macOS
flutter run -d linux      # Linux
flutter run               # Selector interactivo
```

### 4. Configurar IP del Backend (Opcional)

Si el backend no está en `localhost:3000`, puedes configurar la IP desde la interfaz o modificar `lib/core/api_client.dart`:

```dart
static String _baseUrl = 'http://192.168.1.100:3000';
```

---

## Credenciales de Acceso

| Usuario | Contraseña | Rol | Permisos |
|---|---|---|---|
| `admin` | `admin123` | Administrador | Simular ataques, aislar, reconectar, shut down zonas, recuperar sistemas |
| `operator` | `op123` | Operador | Aislar dispositivos, reconectar, contener incidentes, recuperar sistemas |
| `viewer` | `view123` | Observador | Solo visualización (sin acciones de respuesta) |

---

## API REST Endpoints

### Autenticación

| Método | Endpoint | Descripción | Body |
|---|---|---|---|
| `POST` | `/api/auth/login` | Iniciar sesión | `{ "username": "admin", "password": "admin123" }` |

### Dispositivos

| Método | Endpoint | Descripción |
|---|---|---|
| `GET` | `/api/devices` | Obtener todos los dispositivos de la red |
| `POST` | `/api/devices` | Registrar un nuevo dispositivo |

### Eventos de Seguridad

| Método | Endpoint | Descripción |
|---|---|---|
| `GET` | `/api/events` | Obtener todos los eventos de seguridad (ordenados por timestamp descendente) |

### Incidentes

| Método | Endpoint | Descripción |
|---|---|---|
| `GET` | `/api/incidents` | Obtener incidentes con su timeline de eventos |

### Sistemas Críticos

| Método | Endpoint | Descripción |
|---|---|---|
| `GET` | `/api/systems` | Obtener sistemas críticos y su estado |

### Simulación

| Método | Endpoint | Descripción | Body |
|---|---|---|---|
| `POST` | `/api/simulate` | Iniciar simulación de ransomware | `{ "role": "admin" }` |
| `POST` | `/api/reset` | Reiniciar toda la simulación | `{ "role": "admin" }` |

### Respuesta a Incidentes (SOC)

| Método | Endpoint | Descripción | Body |
|---|---|---|---|
| `POST` | `/api/respond/isolate` | Aislar dispositivo de la red | `{ "deviceId": "d4", "role": "admin" }` |
| `POST` | `/api/respond/reconnect` | Reconectar dispositivo aislado | `{ "deviceId": "d4", "role": "admin" }` |
| `POST` | `/api/respond/shutdown_zone` | Apagado de emergencia de zona | `{ "zone": "OT", "role": "admin" }` |
| `POST` | `/api/respond/contain` | Marcar incidente como contenido | `{ "incidentId": "uuid", "role": "admin" }` |
| `POST` | `/api/respond/recover` | Recuperar sistema crítico | `{ "systemId": "cs1", "role": "admin" }` |

---

## Modelos de Datos (SQLite)

### Tabla `users`
| Campo | Tipo | Descripción |
|---|---|---|
| id | TEXT PK | Identificador único |
| name | TEXT | Nombre completo |
| role | TEXT | admin / operator / viewer |
| username | TEXT UNIQUE | Nombre de usuario |
| password | TEXT | Contraseña (texto plano en simulación) |

### Tabla `devices`
| Campo | Tipo | Descripción |
|---|---|---|
| id | TEXT PK | Identificador único |
| name | TEXT | Nombre del dispositivo |
| ip | TEXT | Dirección IP |
| type | TEXT | Tipo: router, pc, plc, hmi, server |
| zone | TEXT | Zona: IT, DMZ, OT |
| isTrusted | INTEGER | 1 = confiable, 0 = no confiable |
| status | TEXT | online / compromised / offline |
| isIsolated | INTEGER | 0 = conectado, 1 = aislado |

### Tabla `security_events`
| Campo | Tipo | Descripción |
|---|---|---|
| id | TEXT PK | Identificador único |
| type | TEXT | Tipo de evento |
| severity | TEXT | low / medium / high / critical |
| timestamp | TEXT | Fecha ISO 8601 |
| description | TEXT | Descripción del evento |

### Tabla `critical_systems`
| Campo | Tipo | Descripción |
|---|---|---|
| id | TEXT PK | Identificador único |
| name | TEXT | Nombre del sistema |
| status | TEXT | operational / degraded / down |
| dependencies | TEXT | JSON array de sistemas dependientes |

### Tabla `incidents`
| Campo | Tipo | Descripción |
|---|---|---|
| id | TEXT PK | Identificador único |
| type | TEXT | ransomware / intrusion_attempt |
| severity | TEXT | critical / high / medium / low |
| status | TEXT | active / contained / resolved |
| startedAt | TEXT | Fecha ISO 8601 |
| explanation | TEXT | Análisis de causa raíz en lenguaje natural |

### Tabla `incident_events`
| Campo | Tipo | Descripción |
|---|---|---|
| id | TEXT PK | Identificador único |
| incidentId | TEXT FK | Referencia al incidente |
| timestamp | TEXT | Fecha ISO 8601 |
| description | TEXT | Descripción del evento en la timeline |
| deviceId | TEXT FK | Dispositivo afectado (opcional) |

### Tabla `login_attempts`
| Campo | Tipo | Descripción |
|---|---|---|
| username | TEXT PK | Nombre de usuario |
| attempts | INTEGER | Conteo de intentos fallidos consecutivos |
| lastAttempt | TEXT | Fecha del último intento |

---

## Motor de Amenazas (Threat Engine)

El motor de amenazas (`threatEngine.js`) implementa la lógica central de simulación:

### Detección de Fuerza Bruta
- Cuenta intentos fallidos de login por usuario.
- Al alcanzar 5 intentos consecutivos, genera un evento de severidad **high**.
- Alimenta el estado de correlación para detectar intrusiones.

### Dispositivos Desconocidos
- Al registrar un dispositivo con `isTrusted: false`, genera un evento de severidad **medium**.
- Alimenta el estado de correlación.

### Correlación de Eventos
- Si ocurren **intentos de fuerza bruta** + **dispositivo desconocido** simultáneamente, se crea un incidente de tipo `intrusion_attempt` con severidad **high**.

### Propagación de Ransomware
1. Se crea un incidente de tipo `ransomware` con severidad **critical**.
2. Itera sobre todos los dispositivos en zona **OT** con un retardo de 4 segundos entre cada uno.
3. **Antes de infectar**, verifica si el dispositivo está aislado (`isIsolated = 1`). Si lo está, bloquea la infección.
4. Dispositivos no aislados cambian a estado `compromised` y pierden confianza (`isTrusted = 0`).

### Degradación en Cascada
- Cuando al menos un dispositivo OT está comprometido, el **Energy Grid** pasa a estado `down`.
- Si Energy Grid cae, **Water Plant** colapsa (depende de energía).
- Si Water Plant o Energy Grid caen, **Textile Production** colapsa.
- Cada colapsa genera una entrada en la timeline del incidente con la causa raíz.

### Acciones de Respuesta

| Acción | Efecto en Base de Datos |
|---|---|
| **Isolate Device** | `isIsolated = 1`, `status = 'offline'` |
| **Reconnect Device** | `isIsolated = 0`, `status = 'online'`, `isTrusted = 1` |
| **Shutdown Zone** | Todos los dispositivos de la zona: `isIsolated = 1`, `status = 'offline'` |
| **Contain Incident** | `incidents.status = 'contained'` |
| **Recover System** | `critical_systems.status = 'operational'`, limpia eventos de seguridad |

---

## Guía de Uso (Flujo de Simulación)

### Flujo Completo de Kill Chain y Mitigación

1. **Iniciar Sesión** → Usar credenciales `admin` / `admin123`
2. **Dashboard** → Observar el estado seguro del sistema (Risk Score = 0)
3. **Simular Ataque** → Presionar el botón "Simular ataque" (solo visible para admin)
4. **Observar Propagación** → En la pestaña "Red", ver cómo los dispositivos OT cambian a rojo (comprometidos) con retardo real
5. **Aislar Dispositivos** → En la pestaña "Red", seleccionar un PLC infectado y presionar "AISLAR"
   - Si actúas rápido, el dispositivo se aísla antes de ser infectado
   - Los dispositivos aislados muestran estado offline con indicador visual
6. **Verificar Contención** → El motor de ransomware respeta el aislamiento: dispositivos aislados no se infectan
7. **Contener Incidente** → En la pestaña "Incidentes", presionar "CONTENER" sobre el incidente activo
   - Se muestra el **Root Cause Analysis** con explicación en lenguaje natural
8. **Recuperar Sistemas** → En la pestaña "Infraestructura", presionar "RECUPERAR" sobre cada sistema caído
   - Energy Grid → Water Plant → Textile Production
9. **Verificar Misión Cumplida** → Cuando Risk Score = 0, todos los sistemas operativos y dispositivos reconectados, se muestra overlay de éxito

### Credenciales Rápidas para Demo

```
Admin:     admin / admin123
Operator:  operator / op123
Viewer:    viewer / view123
```

---

## Marco NIST Cybersecurity Framework

SafeGrid Local implementa las 5 funciones del NIST CSF:

| Fase NIST | Implementación en SafeGrid |
|---|---|
| **Identificar** | Inventario de dispositivos IT/OT, clasificación por zonas (Purdue Model), sistemas críticos mapeados con dependencias |
| **Proteger** | Modelo de confianza (isTrusted), segmentación de red por zonas, autenticación por roles |
| **Detectar** | Motor de correlación de eventos, detección de fuerza bruta, identificación de dispositivos desconocidos, monitoreo en tiempo real |
| **Responder** | Aislamiento de dispositivos, shutdown de zonas, contención de incidentes, timeline de respuesta SOC |
| **Recuperar** | Restauración de sistemas críticos a estado operativo, reconexión de dispositivos, limpieza de eventos |

---

## Modo Demo (GitHub Pages)

La aplicación funciona automáticamente en **modo demo** cuando se ejecuta desde GitHub Pages u cualquier contexto HTTPS sin backend real. En este modo:

- Todas las llamadas API caen a datos mock en memoria
- Las credenciales se validan localmente
- La simulación de ataques funciona completamente en el cliente
- No se requiere servidor backend

---

## Licencia

MIT License - Copyright (c) 2025 Alejandro Pérez Vázquez

---

<p align="center">
  <em>Desarrollado por Alejandro Pérez Vázquez</em><br/>
  <em>Simulador SOC para Infraestructuras Críticas IT/OT</em>
</p>

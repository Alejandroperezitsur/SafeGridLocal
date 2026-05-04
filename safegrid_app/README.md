# SafeGrid Local 🛡️⚓

SafeGrid Local es un simulador avanzado de ciberseguridad diseñado para visualizar y mitigar ataques en infraestructuras críticas (IT/OT). El objetivo principal es proporcionar una herramienta educativa y operativa para entender cómo un compromiso digital puede transformarse en un fallo físico masivo.

## ✨ Características Principales

- **Dashboard de Riesgo**: Visualización en tiempo real del "Risk Score" del sistema basado en incidentes activos, con animaciones de impacto dinámicas.
- **Mapa de Red (Modelo Purdue)**: Clasificación de dispositivos en capas (IT, DMZ, OT) para visualizar la segmentación de red y la propagación de amenazas.
- **Simulación de Amenazas**: Motor de propagación de Ransomware y ataques de movimiento lateral.
- **Respuesta SOC Inmediata**:
    - **Aislamiento**: Desconexión lógica de dispositivos comprometidos con animaciones realistas de progreso y pasos técnicos.
    - **Contención**: Cierre de brechas de seguridad desde el panel de incidentes (NIST/ISA).
    - **Recuperación**: Proceso de restauración de PLCs y sistemas industriales físicos (Energía/Agua).
- **Enfoque Didáctico**: Explicaciones enriquecidas mediante analogías simples para usuarios sin perfil técnico, facilitando el aprendizaje de conceptos complejos.

## 🛠️ Tecnologías

### Frontend (`safegrid_app`)
- **Flutter**: Framework multiplataforma para una UI fluida y moderna.
- **Riverpod**: Gestión de estado reactiva y desacoplada.
- **Dio**: Cliente HTTP robusto para comunicación con el backend.
- **GoRouter**: Manejo de rutas y navegación.

### Backend (`safegrid_backend`)
- **Node.js + Express**: Servidor de API REST.
- **SQLite**: Persistencia de datos local ligera y eficiente.
- **Threat Engine**: Lógica personalizada para la simulación de propagación de ataques.

## 🚀 Pasos para la Activación

Sigue estos pasos para poner en marcha el simulador en tu entorno local:

### 1. Iniciar el Backend
El backend es esencial para que la aplicación reciba datos y ejecute la lógica de simulación.

1. Abre una terminal y navega a la carpeta `safegrid_backend`.
2. Asegúrate de tener **Node.js** instalado.
3. Instala las dependencias:
   ```bash
   npm install
   ```
4. Inicia el servidor:
   ```bash
   node index.js
   ```
   *El servidor debería reportar que está corriendo en `http://localhost:3000`.*

### 2. Iniciar el Frontend (Flutter)
Una vez que el backend esté activo, puedes lanzar la aplicación.

1. Abre una nueva terminal y navega a la carpeta `safegrid_app`.
2. Descarga los paquetes necesarios:
   ```bash
   flutter pub get
   ```
3. Lanza la aplicación (puedes usar Chrome para web o tu emulador preferido):
   ```bash
   flutter run -d chrome
   ```

## 📂 Estructura del Proyecto

- `safegrid_app/`: Código fuente de la interfaz de usuario Flutter.
- `safegrid_backend/`: Lógica del servidor, base de datos y motor de amenazas.
- `DEFENSE_CHECKLIST.md`: Guía académica complementaria de defensa en profundidad.
- `logo.png`: Identidad visual del sistema.

## 💡 Guía de Uso Rápido
Para experimentar el simulador al máximo:
1. Inicia sesión en la app con credenciales de **Administrador**.
2. En el Dashboard, presiona el botón **"Iniciar simulación (Demo)"**.
3. Observa cómo el nivel de riesgo aumenta y los dispositivos en la pestaña **"Red"** se marcan en rojo.
4. Practica la respuesta a incidentes: selecciona un dispositivo infectado, presiona **"AISLAR"** y observa el proceso de contención.
5. Finalmente, dirígete a **"Infraestructura"** para recuperar los sistemas físicos afectados.

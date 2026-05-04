import 'package:flutter/material.dart';
import 'screen_onboarding.dart';

/// Central registry of all per-screen onboarding slides.
/// Organized by screen key for easy maintenance.

const kDashboardSlides = [
  OnboardingSlide(
    title: '¡Bienvenido al Centro de Control!',
    body: 'Este es tu panel principal. Desde aquí puedes ver el estado general de toda la infraestructura: si hay amenazas activas, cuánto riesgo hay, y qué acción tomar.\n\nPiensa en esto como la sala de control de una planta industrial.',
    icon: Icons.dashboard,
    color: Colors.blueAccent,
  ),
  OnboardingSlide(
    title: 'Nivel de Impacto (Risk Score)',
    body: 'El número grande de colores es el "Nivel de Impacto". Funciona como un semáforo:\n\n🟢 Verde (0-5): Todo seguro.\n🟡 Amarillo (6-15): Algo sospechoso.\n🟠 Naranja (16-49): Hay dispositivos comprometidos.\n🔴 Rojo (50+): Emergencia crítica.',
    icon: Icons.speed,
    color: Colors.orange,
  ),
  OnboardingSlide(
    title: 'Simular un Ataque',
    body: 'El botón "Iniciar simulación" lanza un ataque de RANSOMWARE ficticio dentro del sistema.\n\n¿Qué es Ransomware? Es un virus que "secuestra" los archivos de las computadoras, los encripta (los pone en clave) y exige un pago para devolverlos.\n\nAquí verás cómo se propaga y cómo detenerlo.',
    icon: Icons.play_circle,
    color: Colors.redAccent,
  ),
];

const kNetworkSlides = [
  OnboardingSlide(
    title: 'Mapa de Red (Modelo Purdue)',
    body: 'Esta pantalla muestra TODOS los dispositivos conectados a la red, organizados en 3 zonas según el "Modelo Purdue", un estándar industrial para separar las redes.\n\nCada columna es una zona diferente de la empresa.',
    icon: Icons.account_tree,
    color: Colors.blueAccent,
  ),
  OnboardingSlide(
    title: 'Zona IT (Oficinas)',
    body: '🔵 La columna azul es la "Zona IT" (Information Technology).\n\nAquí están las computadoras de oficina, correos electrónicos, servidores web y todo lo que usa el personal administrativo.\n\nEs como el edificio de oficinas de una fábrica.',
    icon: Icons.computer,
    color: Colors.blue,
  ),
  OnboardingSlide(
    title: 'Zona DMZ (Aduana Digital)',
    body: '🟠 La columna naranja es la "DMZ" (Zona Desmilitarizada).\n\n¿Qué significa? Es un punto de control entre las oficinas (IT) y la fábrica (OT). Todo el tráfico de datos DEBE pasar por aquí y ser inspeccionado.\n\nEs exactamente como una aduana fronteriza: revisa qué entra y qué sale.',
    icon: Icons.shield,
    color: Colors.orange,
  ),
  OnboardingSlide(
    title: 'Zona OT (Fábrica / Planta)',
    body: '🟣 La columna morada es la "Zona OT" (Operational Technology).\n\nAquí están los PLCs (controladores que operan máquinas reales), sensores de temperatura, bombas de agua y turbinas.\n\nSi un virus llega aquí, puede apagar la luz de una ciudad o detener el suministro de agua.',
    icon: Icons.precision_manufacturing,
    color: Colors.purple,
  ),
  OnboardingSlide(
    title: 'Colores de Estado',
    body: '🟢 Verde = Dispositivo sano y operando normalmente.\n🟠 Naranja = Dispositivo no verificado (podría ser un intruso).\n🔴 Rojo = ¡Dispositivo infectado! Está comprometido por malware.\n⚪ Gris = Dispositivo aislado (desconectado a propósito para proteger la red).\n\nLos dispositivos rojos PARPADEAN para alertarte visualmente.',
    icon: Icons.palette,
    color: Colors.green,
  ),
  OnboardingSlide(
    title: '¿Qué es "Aislar"?',
    body: 'El botón "AISLAR" simula la desconexión física del cable de red de un equipo infectado.\n\nEn la vida real, un analista SOC desactiva el puerto del switch de red para que el virus no se propague a otros sistemas.\n\nEs como una cuarentena: el equipo sigue operando localmente, pero no puede "contagiar" a nadie más.',
    icon: Icons.link_off,
    color: Colors.blueAccent,
  ),
];

const kIncidentsSlides = [
  OnboardingSlide(
    title: 'Panel de Incidentes (SOC)',
    body: 'Un "Incidente" es un evento de seguridad grave que requiere atención humana inmediata.\n\nEsta pantalla simula lo que ve un analista del SOC (Security Operations Center): el equipo de personas que vigilan la red 24/7, como guardias de seguridad digitales.',
    icon: Icons.security,
    color: Colors.redAccent,
  ),
  OnboardingSlide(
    title: 'Severidad y Estado',
    body: '🔴 CRÍTICA: Impacto máximo. El ransomware está activo y propagándose.\n🟠 ALTA: Compromiso parcial detectado.\n\nEstado ACTIVO = el ataque sigue en curso.\nEstado CONTENIDO = se detuvo la propagación.\nEstado RESUELTO = todo volvió a la normalidad.',
    icon: Icons.thermostat,
    color: Colors.orange,
  ),
  OnboardingSlide(
    title: '¿Qué es "Contener"?',
    body: 'El botón "CONTENER AHORA" simula la respuesta SOC bajo el framework NIST:\n\n1. Identificar la vulnerabilidad.\n2. Cerrar el puerto o protocolo comprometido.\n3. Neutralizar el payload (código malicioso).\n\n"Payload" = Es la parte del virus que ejecuta el daño real. Piénsalo como la "ojiva" de un misil.',
    icon: Icons.gpp_good,
    color: Colors.green,
  ),
  OnboardingSlide(
    title: 'Timeline de Eventos',
    body: 'Cada incidente tiene una línea de tiempo que muestra EXACTAMENTE qué pasó y cuándo.\n\nEsto es clave para la "Investigación Forense": reconstruir el ataque paso a paso después de contenerlo, para entender cómo entró el atacante y evitar que vuelva a pasar.',
    icon: Icons.timeline,
    color: Colors.blueAccent,
  ),
];

const kInfraSlides = [
  OnboardingSlide(
    title: 'Infraestructura Crítica',
    body: 'Aquí ves los PROCESOS FÍSICOS que dependen de la red:\n\n⚡ Red eléctrica (Energy Grid)\n💧 Bombas de agua (Water Pump)\n🌡️ Refrigeración (HVAC)\n\nSi un ataque llega a los PLCs que controlan estas máquinas, los servicios del mundo real se detienen.',
    icon: Icons.factory,
    color: Colors.purple,
  ),
  OnboardingSlide(
    title: '¿Qué es "Energy Grid"?',
    body: 'Es el sistema que distribuye electricidad. En esta simulación, depende de un PLC (mini-computador industrial).\n\nSi el PLC se infecta, pierde el control sobre los interruptores y se produce un apagón.',
    icon: Icons.bolt,
    color: Colors.amber,
  ),
  OnboardingSlide(
    title: '¿Qué significa "Recuperar"?',
    body: 'Simula la restauración industrial:\n1. Reiniciar PLC a modo seguro.\n2. Limpiar malware de la memoria.\n3. Reconectar con el servidor SCADA.\n4. Reactivar el proceso físico.\n\nEste proceso requiere precisión y tiempo para evitar daños físicos.',
    icon: Icons.build_circle,
    color: Colors.green,
  ),
  OnboardingSlide(
    title: 'Fallas en Cascada',
    body: 'Cuando un componente falla, puede provocar que otros fallen también. Esto se llama "Falla en Cascada".\n\nEjemplo: Si el PLC de energía se infecta → se corta la electricidad → los servidores se apagan → la bomba de agua no recibe órdenes → se interrumpe el suministro de agua.\n\nEs como el efecto dominó: una pieza tumba a todas las demás.',
    icon: Icons.waves,
    color: Colors.red,
  ),
];

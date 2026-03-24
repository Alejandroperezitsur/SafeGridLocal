import 'package:flutter/material.dart';

class EducationalScreen extends StatelessWidget {
  const EducationalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        const Text(
          'Cybersecurity in Critical Infrastructure',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        _buildSectionCard(
          context,
          title: 'What is SCADA?',
          content: 'SCADA (Supervisory Control and Data Acquisition) is a control system architecture comprising computers, networked data communications and graphical user interfaces for high-level supervision of machines and processes. It is used in energy, manufacturing, and water processing.',
          icon: Icons.monitor_heart,
          color: Colors.blue,
        ),
        _buildSectionCard(
          context,
          title: 'What is a PLC?',
          content: 'A Programmable Logic Controller (PLC) is an industrial digital computer which has been ruggedized and adapted for the control of manufacturing processes, such as assembly lines, or robotic devices.',
          icon: Icons.memory,
          color: Colors.green,
        ),
        _buildSectionCard(
          context,
          title: 'The Purdue Model & Segmentation',
          content: 'The Purdue Enterprise Reference Architecture separates corporate (IT) networks from industrial (OT) networks into different "Levels" (0 to 5) using Demilitarized Zones (DMZs). This segmenting ensures that an attack on corporate email doesn\'t easily reach the Water Plant PLCs.',
          icon: Icons.layers,
          color: Colors.purple,
        ),
        _buildSectionCard(
          context,
          title: 'Real-world incident: Stuxnet (2010)',
          content: 'A malicious computer worm targeting SCADA systems. It caused substantial damage to Iran\'s nuclear program by attacking Siemens PLCs, proving that cyber threats can physically destroy industrial hardware.',
          icon: Icons.bug_report,
          color: Colors.red,
        ),
        _buildSectionCard(
          context,
          title: 'Real-world incident: Colonial Pipeline (2021)',
          content: 'A ransomware attack took down the largest fuel pipeline in the US. Attackers breached the IT network, forcing operators to shut down the OT network preemptively, halting 45% of the fuel supply for the East Coast.',
          icon: Icons.local_gas_station,
          color: Colors.orange,
        ),
      ],
    );
  }

  Widget _buildSectionCard(BuildContext context, {required String title, required String content, required IconData icon, required Color color}) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(content, style: const TextStyle(height: 1.5)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

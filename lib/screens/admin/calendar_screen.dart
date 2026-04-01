import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../models/session_model.dart';
import '../../models/formation_model.dart';
import '../../services/formation_service.dart';

class CalendarAdminScreen extends StatefulWidget {
  const CalendarAdminScreen({super.key});

  @override
  State<CalendarAdminScreen> createState() => _CalendarAdminScreenState();
}

class _CalendarAdminScreenState extends State<CalendarAdminScreen>
    with SingleTickerProviderStateMixin {
  // ── État calendrier ──────────────────────────────────────
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  // ── Filtres ──────────────────────────────────────────────
  String? _filtreFormationId;
  String? _filtreStatut;

  // ── Vues ─────────────────────────────────────────────────
  bool _isListView = false;

  static const _teal = Color(0xFF00796B);
  static const _darkTeal = Color(0xFF004D40);

  // ── Couleurs par statut ───────────────────────────────────
  static const Map<String, Color> _statutColors = {
    'planifiee': Color(0xFF2563EB),
    'en_cours': Color(0xFFD97706),
    'terminee': Color(0xFF00796B),
  };

  static const Map<String, String> _statutLabels = {
    'planifiee': 'Planifiée',
    'en_cours': 'En cours',
    'terminee': 'Terminée',
  };

  // ── Groupement sessions par jour ─────────────────────────
  Map<DateTime, List<SessionModel>> _groupParJour(
      List<SessionModel> sessions) {
    final map = <DateTime, List<SessionModel>>{};
    for (final s in sessions) {
      final jour = DateTime(s.date.year, s.date.month, s.date.day);
      map.putIfAbsent(jour, () => []).add(s);
    }
    return map;
  }

  List<SessionModel> _sessionsForDay(
      Map<DateTime, List<SessionModel>> map, DateTime day) {
    final key = DateTime(day.year, day.month, day.day);
    return map[key] ?? [];
  }

  List<SessionModel> _applyFiltres(List<SessionModel> sessions) {
    return sessions.where((s) {
      if (_filtreFormationId != null &&
          s.formationId != _filtreFormationId) return false;
      if (_filtreStatut != null && s.statut != _filtreStatut) return false;
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFB),
      body: StreamBuilder<QuerySnapshot>(
        stream:
        FirebaseFirestore.instance.collection('sessions').snapshots(),
        builder: (context, sessionsSnap) {
          final allSessions = (sessionsSnap.data?.docs ?? [])
              .map((d) =>
              SessionModel.fromMap(d.data() as Map<String, dynamic>, d.id))
              .toList();

          final filtered = _applyFiltres(allSessions);
          final sessionsByDay = _groupParJour(filtered);
          final selectedSessions =
          _sessionsForDay(sessionsByDay, _selectedDay);

          return NestedScrollView(
            headerSliverBuilder: (context, _) => [
              _buildAppBar(),
            ],
            body: Column(
              children: [
                // ── Barre filtres ──────────────────────────
                _FiltresBar(
                  filtreStatut: _filtreStatut,
                  filtreFormationId: _filtreFormationId,
                  isListView: _isListView,
                  onStatutChanged: (v) =>
                      setState(() => _filtreStatut = v),
                  onFormationChanged: (v) =>
                      setState(() => _filtreFormationId = v),
                  onToggleView: () =>
                      setState(() => _isListView = !_isListView),
                ),

                Expanded(
                  child: _isListView
                      ? _ListView(
                    sessions: filtered,
                    statutColors: _statutColors,
                    statutLabels: _statutLabels,
                  )
                      : _CalendarView(
                    focusedDay: _focusedDay,
                    selectedDay: _selectedDay,
                    calendarFormat: _calendarFormat,
                    sessionsByDay: sessionsByDay,
                    selectedSessions: selectedSessions,
                    statutColors: _statutColors,
                    statutLabels: _statutLabels,
                    onDaySelected: (selected, focused) {
                      setState(() {
                        _selectedDay = selected;
                        _focusedDay = focused;
                      });
                    },
                    onFormatChanged: (format) {
                      setState(() => _calendarFormat = format);
                    },
                    onPageChanged: (focused) {
                      setState(() => _focusedDay = focused);
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 140,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: _teal,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_teal, _darkTeal],
            ),
          ),
          child: const SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 8),
                  Text('Administration 🛠️',
                      style:
                      TextStyle(color: Colors.white70, fontSize: 15)),
                  SizedBox(height: 4),
                  Text('Calendrier des sessions',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Barre de filtres ───────────────────────────────────────────────────────────
class _FiltresBar extends StatelessWidget {
  final String? filtreStatut;
  final String? filtreFormationId;
  final bool isListView;
  final ValueChanged<String?> onStatutChanged;
  final ValueChanged<String?> onFormationChanged;
  final VoidCallback onToggleView;

  const _FiltresBar({
    required this.filtreStatut,
    required this.filtreFormationId,
    required this.isListView,
    required this.onStatutChanged,
    required this.onFormationChanged,
    required this.onToggleView,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      child: Row(
        children: [
          // ── Filtre statut ──────────────────────────────
          Expanded(
            child: _DropdownFiltre<String>(
              hint: 'Statut',
              value: filtreStatut,
              icone: Icons.flag_outlined,
              items: const [
                DropdownMenuItem(value: 'planifiee', child: Text('Planifiée')),
                DropdownMenuItem(value: 'en_cours', child: Text('En cours')),
                DropdownMenuItem(value: 'terminee', child: Text('Terminée')),
              ],
              onChanged: onStatutChanged,
            ),
          ),
          const SizedBox(width: 8),

          // ── Filtre formation ───────────────────────────
          Expanded(
            child: StreamBuilder<List<FormationModel>>(
              stream: FormationService().getAllFormations(),
              builder: (context, snap) {
                final formations = snap.data ?? [];
                return _DropdownFiltre<String>(
                  hint: 'Formation',
                  value: filtreFormationId,
                  icone: Icons.school_outlined,
                  items: formations
                      .map((f) => DropdownMenuItem(
                    value: f.id,
                    child: Text(f.titre,
                        overflow: TextOverflow.ellipsis),
                  ))
                      .toList(),
                  onChanged: onFormationChanged,
                );
              },
            ),
          ),
          const SizedBox(width: 8),

          // ── Toggle vue calendrier / liste ──────────────
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF00796B).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              onPressed: onToggleView,
              icon: Icon(
                isListView
                    ? Icons.calendar_month_outlined
                    : Icons.view_list_outlined,
                color: const Color(0xFF00796B),
                size: 22,
              ),
              tooltip: isListView ? 'Vue calendrier' : 'Vue liste',
            ),
          ),
        ],
      ),
    );
  }
}

// ── Dropdown filtre générique ──────────────────────────────────────────────────
class _DropdownFiltre<T> extends StatelessWidget {
  final String hint;
  final T? value;
  final IconData icone;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  const _DropdownFiltre({
    required this.hint,
    required this.value,
    required this.icone,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F9F7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF00796B).withValues(alpha: 0.2)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          hint: Row(
            children: [
              Icon(icone, size: 14, color: Colors.grey.shade500),
              const SizedBox(width: 6),
              Text(hint,
                  style:
                  TextStyle(fontSize: 12, color: Colors.grey.shade500)),
            ],
          ),
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down,
              size: 16, color: Color(0xFF00796B)),
          style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF1A1A2E),
              fontWeight: FontWeight.w500),
          items: [
            DropdownMenuItem<T>(
              value: null,
              child: Text('Tous',
                  style: TextStyle(color: Colors.grey.shade500)),
            ),
            ...items,
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ── Vue Calendrier ─────────────────────────────────────────────────────────────
class _CalendarView extends StatelessWidget {
  final DateTime focusedDay;
  final DateTime selectedDay;
  final CalendarFormat calendarFormat;
  final Map<DateTime, List<SessionModel>> sessionsByDay;
  final List<SessionModel> selectedSessions;
  final Map<String, Color> statutColors;
  final Map<String, String> statutLabels;
  final void Function(DateTime, DateTime) onDaySelected;
  final void Function(CalendarFormat) onFormatChanged;
  final void Function(DateTime) onPageChanged;

  const _CalendarView({
    required this.focusedDay,
    required this.selectedDay,
    required this.calendarFormat,
    required this.sessionsByDay,
    required this.selectedSessions,
    required this.statutColors,
    required this.statutLabels,
    required this.onDaySelected,
    required this.onFormatChanged,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Calendrier ─────────────────────────────────
        Container(
          color: Colors.white,
          child: TableCalendar<SessionModel>(
            firstDay: DateTime(2020),
            lastDay: DateTime(2030),
            focusedDay: focusedDay,
            selectedDayPredicate: (day) => isSameDay(selectedDay, day),
            calendarFormat: calendarFormat,
            eventLoader: (day) {
              final key = DateTime(day.year, day.month, day.day);
              return sessionsByDay[key] ?? [];
            },
            startingDayOfWeek: StartingDayOfWeek.monday,
            locale: 'fr_FR',
            availableCalendarFormats: const {
              CalendarFormat.month: 'Mois',
              CalendarFormat.twoWeeks: '2 semaines',
              CalendarFormat.week: 'Semaine',
            },
            headerStyle: const HeaderStyle(
              formatButtonShowsNext: false,
              titleCentered: true,
              titleTextStyle: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E)),
              formatButtonDecoration: BoxDecoration(
                color: Color(0xFFF0F9F7),
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              formatButtonTextStyle: TextStyle(
                  color: Color(0xFF00796B), fontSize: 12),
              leftChevronIcon:
              Icon(Icons.chevron_left, color: Color(0xFF00796B)),
              rightChevronIcon:
              Icon(Icons.chevron_right, color: Color(0xFF00796B)),
            ),
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: const Color(0xFF00796B).withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              todayTextStyle: const TextStyle(
                  color: Color(0xFF00796B), fontWeight: FontWeight.bold),
              selectedDecoration: const BoxDecoration(
                color: Color(0xFF00796B),
                shape: BoxShape.circle,
              ),
              selectedTextStyle: const TextStyle(color: Colors.white),
              markersMaxCount: 3,
              markerDecoration: const BoxDecoration(
                color: Color(0xFF00796B),
                shape: BoxShape.circle,
              ),
              markerSize: 5,
              markerMargin: const EdgeInsets.symmetric(horizontal: 1),
              outsideDaysVisible: false,
              weekendTextStyle:
              TextStyle(color: Colors.grey.shade500),
            ),
            // ── Marqueurs colorés par statut ─────────────
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, day, events) {
                if (events.isEmpty) return null;
                final colors = events
                    .take(3)
                    .map((e) =>
                statutColors[e.statut] ?? const Color(0xFF00796B))
                    .toSet()
                    .toList();
                return Positioned(
                  bottom: 4,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: colors
                        .map((c) => Container(
                      width: 5,
                      height: 5,
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      decoration: BoxDecoration(
                          color: c, shape: BoxShape.circle),
                    ))
                        .toList(),
                  ),
                );
              },
            ),
            onDaySelected: onDaySelected,
            onFormatChanged: onFormatChanged,
            onPageChanged: onPageChanged,
          ),
        ),

        // ── Séparateur avec date sélectionnée ──────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          color: const Color(0xFFF8FAFB),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  color: const Color(0xFF00796B),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                _formatDateHeader(selectedDay),
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF1A1A2E)),
              ),
              const Spacer(),
              if (selectedSessions.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00796B).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${selectedSessions.length} session${selectedSessions.length > 1 ? 's' : ''}',
                    style: const TextStyle(
                        color: Color(0xFF00796B),
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        ),

        // ── Liste sessions du jour sélectionné ─────────
        Expanded(
          child: selectedSessions.isEmpty
              ? _EmptyDay()
              : ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
            itemCount: selectedSessions.length,
            itemBuilder: (context, i) => _SessionTile(
              session: selectedSessions[i],
              statutColor:
              statutColors[selectedSessions[i].statut] ??
                  const Color(0xFF00796B),
              statutLabel:
              statutLabels[selectedSessions[i].statut] ??
                  'Planifiée',
            ),
          ),
        ),
      ],
    );
  }

  String _formatDateHeader(DateTime day) {
    const jours = [
      'Lundi', 'Mardi', 'Mercredi', 'Jeudi',
      'Vendredi', 'Samedi', 'Dimanche'
    ];
    const mois = [
      'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'
    ];
    final jourid = day.weekday - 1;
    return '${jours[jourid]} ${day.day} ${mois[day.month - 1]} ${day.year}';
  }
}

// ── Vue Liste ──────────────────────────────────────────────────────────────────
class _ListView extends StatelessWidget {
  final List<SessionModel> sessions;
  final Map<String, Color> statutColors;
  final Map<String, String> statutLabels;

  const _ListView({
    required this.sessions,
    required this.statutColors,
    required this.statutLabels,
  });

  @override
  Widget build(BuildContext context) {
    if (sessions.isEmpty) return _EmptyDay();

    // Trier par date
    final sorted = [...sessions]
      ..sort((a, b) => a.date.compareTo(b.date));

    // Grouper par mois
    final Map<String, List<SessionModel>> parMois = {};
    for (final s in sorted) {
      const mois = [
        'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
        'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
      ];
      final key = '${mois[s.date.month - 1]} ${s.date.year}';
      parMois.putIfAbsent(key, () => []).add(s);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
      children: [
        for (final entry in parMois.entries) ...[
          // ── Header mois ──────────────────────────────
          Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 8),
            child: Row(
              children: [
                Container(
                  width: 4, height: 18,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00796B),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Text(entry.key,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Color(0xFF1A1A2E))),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00796B).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${entry.value.length}',
                    style: const TextStyle(
                        color: Color(0xFF00796B),
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          // ── Sessions du mois ─────────────────────────
          for (final s in entry.value)
            _SessionTile(
              session: s,
              statutColor:
              statutColors[s.statut] ?? const Color(0xFF00796B),
              statutLabel: statutLabels[s.statut] ?? 'Planifiée',
              showDate: true,
            ),
        ],
      ],
    );
  }
}

// ── Tuile session ──────────────────────────────────────────────────────────────
class _SessionTile extends StatelessWidget {
  final SessionModel session;
  final Color statutColor;
  final String statutLabel;
  final bool showDate;

  const _SessionTile({
    required this.session,
    required this.statutColor,
    required this.statutLabel,
    this.showDate = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Barre couleur statut ─────────────────────
            Container(
              width: 4,
              height: 60,
              decoration: BoxDecoration(
                color: statutColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titre + badge statut
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          session.titre.isEmpty ? 'Session' : session.titre,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Color(0xFF1A1A2E)),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: statutColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(statutLabel,
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: statutColor)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Formation
                  if (session.formationTitre.isNotEmpty)
                    Row(children: [
                      Icon(Icons.school_outlined,
                          size: 12, color: Colors.grey.shade400),
                      const SizedBox(width: 4),
                      Text(session.formationTitre,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade500)),
                    ]),
                  const SizedBox(height: 4),

                  // Date + heure
                  Row(
                    children: [
                      if (showDate) ...[
                        Icon(Icons.calendar_today_outlined,
                            size: 12, color: Colors.grey.shade400),
                        const SizedBox(width: 4),
                        Text(
                          '${session.date.day.toString().padLeft(2, '0')}/${session.date.month.toString().padLeft(2, '0')}/${session.date.year}',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade500),
                        ),
                        const SizedBox(width: 12),
                      ],
                      if (session.heureDebut.isNotEmpty) ...[
                        Icon(Icons.schedule_outlined,
                            size: 12, color: Colors.grey.shade400),
                        const SizedBox(width: 4),
                        Text(
                          session.heureFin.isNotEmpty
                              ? '${session.heureDebut} → ${session.heureFin}'
                              : session.heureDebut,
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade500),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // ── Compteur inscrits temps réel ─────────────
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('sessions')
                  .doc(session.id)
                  .collection('inscrits')
                  .snapshots(),
              builder: (context, snap) {
                final count = snap.data?.docs.length ?? 0;
                return Column(
                  children: [
                    Text(
                      '$count',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: count >= session.maxParticipants
                              ? Colors.red
                              : const Color(0xFF00796B)),
                    ),
                    Text(
                      '/${session.maxParticipants}',
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade400),
                    ),
                    Icon(Icons.people_outline,
                        size: 14, color: Colors.grey.shade400),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ── État vide ──────────────────────────────────────────────────────────────────
class _EmptyDay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_available_outlined,
              size: 56,
              color: const Color(0xFF00796B).withValues(alpha: 0.2)),
          const SizedBox(height: 12),
          Text('Aucune session ce jour',
              style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 14,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
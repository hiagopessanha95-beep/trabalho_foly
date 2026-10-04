import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:table_calendar/table_calendar.dart';
import 'login.dart';

class Principal extends StatefulWidget {
  const Principal({super.key});

  @override
  State<Principal> createState() => _PrincipalState();
}

class _PrincipalState extends State<Principal> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  final _eventosCollection =
      FirebaseFirestore.instance.collection('eventos');

  static const Color roxoPrincipal = Color(0xFF6A11CB);
  static const Color roxoSecundario = Color(0xFF8E2DE2);

  DateTime _apenasData(DateTime d) {
    return DateTime(d.year, d.month, d.day);
  }

  // Verifica se o usuário está na coleção "administradores"
  Future<bool> _ehAdministrador(User? user) async {
    if (user == null || user.email == null) {
      return false;
    }

    final resultado = await FirebaseFirestore.instance
        .collection('administradores')
        .where('email', isEqualTo: user.email)
        .limit(1)
        .get();

    return resultado.docs.isNotEmpty;
  }

  // Adiciona evento
  Future<void> _adicionarEvento(String texto) async {
    if (_selectedDay == null || texto.trim().isEmpty) {
      return;
    }

    await _eventosCollection.add({
      'data': Timestamp.fromDate(
        _apenasData(_selectedDay!),
      ),
      'descricao': texto.trim(),
      'criadoEm': FieldValue.serverTimestamp(),
    });
  }

  // Remove evento
  Future<void> _removerEvento(String docId) async {
    await _eventosCollection.doc(docId).delete();
  }

  // Abre diálogo para adicionar evento
  void _abrirDialogoAdicionarEvento() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Novo evento',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: roxoPrincipal,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Descrição do evento',
            filled: true,
            fillColor: const Color(0xFFF5F3FB),
            isDense: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.0),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.0),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14.0),
              borderSide: const BorderSide(
                color: roxoPrincipal,
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 14,
              horizontal: 14,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[600],
            ),
            child: const Text('Cancelar'),
          ),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14.0),
              gradient: const LinearGradient(
                colors: [
                  roxoPrincipal,
                  roxoSecundario,
                ],
              ),
            ),
            child: ElevatedButton(
              onPressed: () async {
                await _adicionarEvento(controller.text);

                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14.0),
                ),
              ),
              child: const Text(
                'Adicionar',
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Logout
  Future<void> _sair() async {
    await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const Login(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        final user = authSnapshot.data;
        final logado = user != null;

        final nomeUsuario =
            user?.displayName?.isNotEmpty == true
                ? user!.displayName!
                : user?.email ?? '';

        // Verifica se o usuário é administrador
        return FutureBuilder<bool>(
          future: _ehAdministrador(user),
          builder: (context, adminSnapshot) {
            final ehAdmin = adminSnapshot.data ?? false;

            return Scaffold(
              backgroundColor: const Color(0xFFF5F3FB),
              extendBodyBehindAppBar: false,

              // =========================
              // APP BAR
              // =========================
              appBar: AppBar(
                elevation: 0,
                automaticallyImplyLeading: false,
                flexibleSpace: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        roxoPrincipal,
                        roxoSecundario,
                      ],
                    ),
                  ),
                ),
                title: const Text(
                  'Calendário',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                actions: [
                  if (logado) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                      ),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            nomeUsuario,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.logout,
                        color: Colors.white,
                      ),
                      tooltip: 'Sair',
                      onPressed: _sair,
                    ),
                    const SizedBox(width: 4),
                  ],
                ],
              ),

              // =========================
              // BODY
              // =========================
              body: StreamBuilder<QuerySnapshot>(
                stream: _eventosCollection
                    .orderBy('data')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Erro ao carregar eventos: ${snapshot.error}',
                      ),
                    );
                  }

                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: roxoPrincipal,
                      ),
                    );
                  }

                  final docs = snapshot.data?.docs ?? [];

                  // Agrupa os eventos por data
                  final Map<DateTime,
                      List<QueryDocumentSnapshot>> agrupado = {};

                  for (final doc in docs) {
                    final ts =
                        (doc['data'] as Timestamp).toDate();

                    final chave = _apenasData(ts);

                    agrupado
                        .putIfAbsent(chave, () => [])
                        .add(doc);
                  }

                  List<QueryDocumentSnapshot> eventosDoDia(
                    DateTime dia,
                  ) {
                    return agrupado[_apenasData(dia)] ?? [];
                  }

                  final eventosSelecionados =
                      _selectedDay != null
                          ? eventosDoDia(_selectedDay!)
                          : [];

                  return SingleChildScrollView(
                    child: Column(
                      children: [
                        // =========================
                        // CALENDÁRIO
                        // =========================
                        Container(
                          margin: const EdgeInsets.fromLTRB(
                            64,
                            64,
                            64,
                            16,
                          ),
                          padding: const EdgeInsets.symmetric(
                            vertical: 32,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius:
                                BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    Colors.black.withValues(alpha: 0.08),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: TableCalendar(
                            locale: 'pt_BR',
                            firstDay:
                                DateTime.utc(2026, 1, 1),
                            lastDay:
                                DateTime.utc(2030, 12, 31),
                            focusedDay: _focusedDay,

                            selectedDayPredicate: (day) =>
                                isSameDay(
                              _selectedDay,
                              day,
                            ),

                            eventLoader: eventosDoDia,

                            onDaySelected:
                                (selectedDay, focusedDay) {
                              setState(() {
                                _selectedDay = selectedDay;
                                _focusedDay = focusedDay;
                              });
                            },

                            headerStyle:
                                const HeaderStyle(
                              formatButtonVisible: false,
                              titleCentered: true,
                              titleTextStyle: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: roxoPrincipal,
                              ),
                              leftChevronIcon: Icon(
                                Icons.chevron_left,
                                color: roxoPrincipal,
                              ),
                              rightChevronIcon: Icon(
                                Icons.chevron_right,
                                color: roxoPrincipal,
                              ),
                            ),

                            daysOfWeekStyle:
                                DaysOfWeekStyle(
                              weekdayStyle: TextStyle(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w600,
                              ),
                              weekendStyle: TextStyle(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w600,
                              ),
                            ),

                            calendarStyle:
                                CalendarStyle(
                              outsideDaysVisible: false,

                              todayDecoration:
                                  BoxDecoration(
                                color: roxoSecundario
                                    .withValues(alpha: 0.3),
                                shape: BoxShape.circle,
                              ),

                              selectedDecoration:
                                  const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    roxoPrincipal,
                                    roxoSecundario,
                                  ],
                                ),
                                shape: BoxShape.circle,
                              ),

                              markerDecoration:
                                  const BoxDecoration(
                                color: roxoPrincipal,
                                shape: BoxShape.circle,
                              ),

                              markersMaxCount: 3,
                            ),
                          ),
                        ),

                        // =========================
                        // BOTÃO ADICIONAR EVENTO
                        // SOMENTE ADMIN
                        // =========================
                        if (ehAdmin)
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(
                              horizontal: 16,
                            ),
                            child: SizedBox(
                              width: 1000,
                              height: 52,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius:
                                      BorderRadius.circular(15.0),
                                  gradient: LinearGradient(
                                    colors: _selectedDay == null
                                        ? [
                                            Colors.grey[300]!,
                                            Colors.grey[300]!,
                                          ]
                                        : const [
                                            roxoPrincipal,
                                            roxoSecundario,
                                          ],
                                    begin:
                                        Alignment.centerLeft,
                                    end:
                                        Alignment.centerRight,
                                  ),
                                ),
                                child: ElevatedButton.icon(
                                  onPressed: _selectedDay == null
                                      ? null
                                      : _abrirDialogoAdicionarEvento,

                                  style:
                                      ElevatedButton.styleFrom(
                                    backgroundColor:
                                        Colors.transparent,
                                    shadowColor:
                                        Colors.transparent,
                                    shape:
                                        RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(
                                        15.0,
                                      ),
                                    ),
                                  ),

                                  icon: const Icon(
                                    Icons.add,
                                    color: Colors.white,
                                  ),

                                  label: const Text(
                                    'Adicionar evento',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),

                        // =========================
                        // LISTA DE EVENTOS
                        // =========================
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(
                            horizontal: 32,
                          ),
                          child: eventosSelecionados.isEmpty
                              ? Container(
                                  width: 1000,
                                  padding:
                                      const EdgeInsets.symmetric(
                                    vertical: 32,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius:
                                        BorderRadius.circular(20),
                                  ),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.event_busy,
                                        size: 40,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Nenhum evento neste dia',
                                        style: TextStyle(
                                          color:
                                              Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.separated(
                                  shrinkWrap: true,
                                  physics:
                                      const NeverScrollableScrollPhysics(),

                                  itemCount:
                                      eventosSelecionados.length,

                                  separatorBuilder:
                                      (_, _) =>
                                          const SizedBox(
                                    height: 10,
                                  ),

                                  itemBuilder:
                                      (context, index) {
                                    final doc =
                                        eventosSelecionados[
                                            index];

                                    final descricao =
                                        doc['descricao']
                                            as String;

                                    return Container(
                                      decoration:
                                          BoxDecoration(
                                        color: Colors.white,
                                        borderRadius:
                                            BorderRadius
                                                .circular(16),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors
                                                .black
                                                .withValues(
                                                    alpha: 0.05),
                                            blurRadius: 8,
                                            offset:
                                                const Offset(
                                              0,
                                              3,
                                            ),
                                          ),
                                        ],
                                      ),

                                      child: ListTile(
                                        shape:
                                            RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius
                                                  .circular(16),
                                        ),

                                        leading: Container(
                                          width: 42,
                                          height: 42,
                                          decoration:
                                              BoxDecoration(
                                            shape:
                                                BoxShape.circle,
                                            color:
                                                roxoPrincipal
                                                    .withValues(
                                                        alpha: 0.1),
                                          ),
                                          child:
                                              const Icon(
                                            Icons.event,
                                            color:
                                                roxoPrincipal,
                                          ),
                                        ),

                                        title: Text(
                                          descricao,
                                          style:
                                              const TextStyle(
                                            fontWeight:
                                                FontWeight.w600,
                                          ),
                                        ),

                                        // SOMENTE ADMIN
                                        // PODE EXCLUIR
                                        trailing: ehAdmin
                                            ? IconButton(
                                                icon:
                                                    const Icon(
                                                  Icons
                                                      .delete_outline,
                                                  color: Colors
                                                      .redAccent,
                                                ),
                                                onPressed: () =>
                                                    _removerEvento(
                                                  doc.id,
                                                ),
                                              )
                                            : null,
                                      ),
                                    );
                                  },
                                ),
                        ),

                        const SizedBox(height: 24),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}

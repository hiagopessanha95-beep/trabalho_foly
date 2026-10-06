import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:trabalho_foly/turmas.dart';
import 'login.dart';

typedef _DadosUsuario = ({bool admin, String? turma});

class Principal extends StatefulWidget {
  const Principal({super.key});

  @override
  State<Principal> createState() => _PrincipalState();
}

class _PrincipalState extends State<Principal> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  static const Color roxoPrincipal = Color(0xFF6A11CB);
  static const Color roxoSecundario = Color(0xFF8E2DE2);

  // Subcoleções: turmas/{turma}/eventos e turmas/{turma}/pedidos
  CollectionReference<Map<String, dynamic>> _eventosDe(String turma) =>
      FirebaseFirestore.instance
          .collection('turmas')
          .doc(turma)
          .collection('eventos');

  CollectionReference<Map<String, dynamic>> _pedidosDe(String turma) =>
      FirebaseFirestore.instance
          .collection('turmas')
          .doc(turma)
          .collection('pedidos');

  // Cache dos dados do usuário (admin + turma)
  Future<_DadosUsuario>? _dadosFuture;
  String? _dadosUid;

  // Turma escolhida na tela (usuário sem turma escolhe)
  String? _turmaEscolhida;

  DateTime _apenasData(DateTime d) {
    return DateTime(d.year, d.month, d.day);
  }

  void _mostrarMensagem(String mensagem) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensagem)),
    );
  }

  // =========================
  // PEDIDOS
  // =========================

  // Envia pedido ao administrador
  Future<bool> _enviarPedido(String texto, String turma) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || texto.trim().isEmpty) return false;

    try {
      await _pedidosDe(turma).add({
        'descricao': texto.trim(),
        'turma': turma,
        'uid': user.uid,
        'email': user.email?.toLowerCase(),
        'nome': user.displayName,
        'criadoEm': FieldValue.serverTimestamp(),
      });
      _mostrarMensagem('Pedido enviado ao administrador!');
      return true;
    } catch (e) {
      debugPrint('Erro ao enviar pedido: $e');
      _mostrarMensagem('Erro ao enviar pedido: $e');
      return false;
    }
  }

  // Diálogo para o usuário escrever o pedido
  void _abrirDialogoPedido(String turma) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Pedido ao administrador',
          style: TextStyle(fontWeight: FontWeight.bold, color: roxoPrincipal),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Ex.: adicionar prova de matemática dia 20/10',
            filled: true,
            fillColor: const Color(0xFFF5F3FB),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: roxoPrincipal, width: 1.5),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: roxoPrincipal,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final ok = await _enviarPedido(controller.text, turma);
              if (ok && dialogContext.mounted) Navigator.pop(dialogContext);
            },
            child: const Text('Enviar'),
          ),
        ],
      ),
    ).then((_) => controller.dispose());
  }

  // FILTRO 2 - Aluno: lista só os pedidos que ele mesmo enviou
  void _abrirMeusPedidos(String turma) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        builder: (context, scroll) => StreamBuilder<QuerySnapshot>(
          stream: _pedidosDe(turma).where('uid', isEqualTo: uid).snapshots(),
          builder: (context, snap) {
            if (snap.hasError) {
              return Center(child: Text('Erro: ${snap.error}'));
            }
            if (!snap.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: roxoPrincipal),
              );
            }
            final docs = snap.data!.docs;
            if (docs.isEmpty) {
              return const Center(
                child: Text('Você ainda não enviou pedidos'),
              );
            }
            return ListView.separated(
              controller: scroll,
              padding: const EdgeInsets.all(16),
              itemCount: docs.length,
              separatorBuilder: (_, _) => const Divider(),
              itemBuilder: (context, i) {
                final d = docs[i].data() as Map<String, dynamic>;
                return ListTile(
                  leading:
                      const Icon(Icons.send_outlined, color: roxoPrincipal),
                  title: Text(d['descricao'] ?? ''),
                );
              },
            );
          },
        ),
      ),
    );
  }

  // Administrador: lista de pedidos da turma
  void _abrirPedidos(String turma) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        builder: (context, scroll) => StreamBuilder<QuerySnapshot>(
          stream: _pedidosDe(turma).snapshots(),
          builder: (context, snap) {
            if (snap.hasError) {
              return Center(child: Text('Erro: ${snap.error}'));
            }
            if (!snap.hasData) {
              return const Center(
                child: CircularProgressIndicator(color: roxoPrincipal),
              );
            }
            final docs = snap.data!.docs;
            if (docs.isEmpty) {
              return const Center(child: Text('Nenhum pedido'));
            }
            return ListView.separated(
              controller: scroll,
              padding: const EdgeInsets.all(16),
              itemCount: docs.length,
              separatorBuilder: (_, _) => const Divider(),
              itemBuilder: (context, i) {
                final d = docs[i].data() as Map<String, dynamic>;
                final autor = (d['nome'] as String?)?.isNotEmpty == true
                    ? d['nome']
                    : d['email'] ?? '';
                return ListTile(
                  title: Text(d['descricao'] ?? ''),
                  subtitle: Text('$autor'),
                  trailing: IconButton(
                    icon: const Icon(Icons.check_circle_outline,
                        color: roxoPrincipal),
                    tooltip: 'Concluir (remover)',
                    onPressed: () => _pedidosDe(turma).doc(docs[i].id).delete(),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  // =========================
  // USUÁRIO / TURMA
  // =========================

  // Busca se é administrador e qual a turma do usuário
  Future<_DadosUsuario> _carregarDados(User? user) async {
    if (user == null) {
      return (admin: false, turma: null);
    }

    bool admin = false;
    String? turma;

    try {
      final adminDoc = await FirebaseFirestore.instance
          .collection('administradores')
          .doc(user.uid)
          .get();
      admin = adminDoc.exists;
    } catch (e) {
      debugPrint('Erro ao verificar administrador: $e');
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .get();
      final t = userDoc.data()?['turma'];
      if (t is String && listaTurmas.contains(t)) {
        turma = t;
      }
    } catch (e) {
      debugPrint('Erro ao buscar turma: $e');
    }

    return (admin: admin, turma: turma);
  }

  Future<_DadosUsuario> _dadosPara(User? user) {
    final uid = user?.uid;

    if (_dadosFuture == null || _dadosUid != uid) {
      _dadosUid = uid;
      _dadosFuture = _carregarDados(user);
    }

    return _dadosFuture!;
  }

  // Salva a turma escolhida no perfil do usuário (se estiver logado)
  Future<void> _escolherTurma(User? user, String turma) async {
    setState(() {
      _turmaEscolhida = turma;
      _selectedDay = null;
    });

    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user.uid)
          .set({
        'turma': turma,
        'email': user.email?.toLowerCase(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Erro ao salvar turma: $e');
      _mostrarMensagem('Erro ao salvar turma: $e');
    }
  }

  // =========================
  // EVENTOS
  // =========================

  // Adiciona evento na turma que está sendo exibida
  Future<bool> _adicionarEvento(String texto, String turma) async {
    if (_selectedDay == null || texto.trim().isEmpty) {
      return false;
    }

    try {
      await _eventosDe(turma).add({
        'data': Timestamp.fromDate(
          _apenasData(_selectedDay!),
        ),
        'descricao': texto.trim(),
        'turma': turma,
        'criadoEm': FieldValue.serverTimestamp(),
      });
      return true;
    } catch (e) {
      debugPrint('Erro ao adicionar: $e');
      _mostrarMensagem('Erro ao adicionar: $e');
      return false;
    }
  }

  // Remove evento
  Future<void> _removerEvento(String turma, String docId) async {
    try {
      await _eventosDe(turma).doc(docId).delete();
    } catch (e) {
      debugPrint('Erro ao remover: $e');
      _mostrarMensagem('Erro ao remover: $e');
    }
  }

  // Abre diálogo para adicionar evento
  void _abrirDialogoAdicionarEvento(String turma) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Novo evento – $turma',
          style: const TextStyle(
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
              Navigator.pop(dialogContext);
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
                final ok = await _adicionarEvento(controller.text, turma);

                if (ok && dialogContext.mounted) {
                  Navigator.pop(dialogContext);
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
    ).then((_) => controller.dispose());
  }

  // Logout
  Future<void> _sair() async {
    await FirebaseAuth.instance.signOut();

    _dadosFuture = null;
    _dadosUid = null;
    _turmaEscolhida = null;

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const Login(),
      ),
      (route) => false,
    );
  }

  // Tela para escolher a turma (quando o usuário ainda não tem uma)
  Widget _telaEscolherTurma(User? user) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.groups_outlined, size: 48, color: roxoPrincipal),
            const SizedBox(height: 12),
            const Text(
              'Escolha sua turma',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: roxoPrincipal,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Turma',
                filled: true,
                fillColor: const Color(0xFFF5F3FB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              items: listaTurmas
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (t) {
                if (t != null) _escolherTurma(user, t);
              },
            ),
          ],
        ),
      ),
    );
  }

  // Faixa com a turma atual (igual para todos)
  Widget _faixaTurma(String turma) {
    return Container(
      margin: const EdgeInsets.fromLTRB(32, 16, 32, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.groups_outlined, color: roxoPrincipal),
          const SizedBox(width: 10),
          Text(
            'Turma: $turma',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: roxoPrincipal,
            ),
          ),
        ],
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

        final nomeUsuario = user?.displayName?.isNotEmpty == true
            ? user!.displayName!
            : user?.email ?? '';

        return FutureBuilder<_DadosUsuario>(
          future: _dadosPara(user),
          builder: (context, dadosSnapshot) {
            final carregando =
                dadosSnapshot.connectionState == ConnectionState.waiting;

            final ehAdmin = dadosSnapshot.data?.admin ?? false;
            final turmaDoUsuario = dadosSnapshot.data?.turma;

            // Turma exibida: a do perfil (ou a escolhida agora, se ainda não tinha)
            final String? turmaVisivel = turmaDoUsuario ?? _turmaEscolhida;

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
              body: carregando
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: roxoPrincipal,
                      ),
                    )
                  : turmaVisivel == null
                      ? _telaEscolherTurma(user)
                      : _corpo(ehAdmin, turmaVisivel),
            );
          },
        );
      },
    );
  }

  Widget _corpo(bool ehAdmin, String turma) {
    final logado = FirebaseAuth.instance.currentUser != null;

    return StreamBuilder<QuerySnapshot>(
      // FILTRO 1 - só os eventos do mês exibido no calendário
      stream: _eventosDe(turma)
          .where('data',
              isGreaterThanOrEqualTo: Timestamp.fromDate(
                  DateTime(_focusedDay.year, _focusedDay.month, 1)))
          .where('data',
              isLessThan: Timestamp.fromDate(
                  DateTime(_focusedDay.year, _focusedDay.month + 1, 1)))
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Erro ao carregar eventos: ${snapshot.error}',
            ),
          );
        }

        // Spinner só na primeira carga (evita piscar ao trocar de mês/dia)
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(
              color: roxoPrincipal,
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        // Agrupa os eventos por data
        final Map<DateTime, List<QueryDocumentSnapshot>> agrupado = {};

        for (final doc in docs) {
          final ts = (doc['data'] as Timestamp).toDate();
          final chave = _apenasData(ts);

          agrupado.putIfAbsent(chave, () => []).add(doc);
        }

        List<QueryDocumentSnapshot> eventosDoDia(DateTime dia) {
          return agrupado[_apenasData(dia)] ?? [];
        }

        final List<QueryDocumentSnapshot> eventosSelecionados =
            _selectedDay != null ? eventosDoDia(_selectedDay!) : [];

        return SingleChildScrollView(
          child: Column(
            children: [
              // =========================
              // TURMA ATUAL
              // =========================
              _faixaTurma(turma),

              // =========================
              // CALENDÁRIO
              // =========================
              Container(
                margin: const EdgeInsets.fromLTRB(64, 24, 64, 16),
                padding: const EdgeInsets.symmetric(
                  vertical: 32,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: TableCalendar(
                  locale: 'pt_BR',
                  firstDay: DateTime.utc(2026, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  eventLoader: eventosDoDia,
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },
                  onPageChanged: (focusedDay) {
                    setState(() {
                      _focusedDay = focusedDay;
                      _selectedDay = null;
                    });
                  },
                  headerStyle: const HeaderStyle(
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
                  daysOfWeekStyle: DaysOfWeekStyle(
                    weekdayStyle: TextStyle(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
                    weekendStyle: TextStyle(
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  calendarStyle: CalendarStyle(
                    outsideDaysVisible: false,
                    todayDecoration: BoxDecoration(
                      color: roxoSecundario.withValues(alpha: 0.3),
                      shape: BoxShape.circle,
                    ),
                    selectedDecoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          roxoPrincipal,
                          roxoSecundario,
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    markerDecoration: const BoxDecoration(
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                  ),
                  child: SizedBox(
                    width: 1000,
                    height: 52,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15.0),
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
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                      ),
                      child: ElevatedButton.icon(
                        onPressed: _selectedDay == null
                            ? null
                            : () => _abrirDialogoAdicionarEvento(turma),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          disabledBackgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15.0),
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

              // =========================
              // BOTÕES DO ALUNO
              // (enviar pedido + meus pedidos)
              // =========================
              if (!ehAdmin && logado) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: SizedBox(
                    width: 1000,
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: () => _abrirDialogoPedido(turma),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: roxoPrincipal,
                        side: const BorderSide(color: roxoPrincipal),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      icon: const Icon(Icons.send_outlined),
                      label: const Text(
                        'Enviar pedido ao administrador',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: SizedBox(
                    width: 1000,
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: () => _abrirMeusPedidos(turma),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: roxoPrincipal,
                        side: const BorderSide(color: roxoPrincipal),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      icon: const Icon(Icons.list_alt_outlined),
                      label: const Text(
                        'Meus pedidos',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
              ],

              // =========================
              // BOTÃO VER PEDIDOS
              // SOMENTE ADMIN
              // =========================
              if (ehAdmin)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: SizedBox(
                    width: 1000,
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: () => _abrirPedidos(turma),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: roxoPrincipal,
                        side: const BorderSide(color: roxoPrincipal),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      icon: const Icon(Icons.inbox_outlined),
                      label: const Text(
                        'Ver pedidos',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // =========================
              // LISTA DE EVENTOS
              // =========================
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                ),
                child: eventosSelecionados.isEmpty
                    ? Container(
                        width: 1000,
                        padding: const EdgeInsets.symmetric(
                          vertical: 32,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
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
                              _selectedDay == null
                                  ? 'Selecione um dia'
                                  : 'Nenhum evento neste dia',
                              style: TextStyle(
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: eventosSelecionados.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final doc = eventosSelecionados[index];
                          final descricao = doc['descricao'] as String;

                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: ListTile(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              leading: Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: roxoPrincipal.withValues(alpha: 0.1),
                                ),
                                child: const Icon(
                                  Icons.event,
                                  color: roxoPrincipal,
                                ),
                              ),
                              title: Text(
                                descricao,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),

                              // SOMENTE ADMIN PODE EXCLUIR
                              trailing: ehAdmin
                                  ? IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: Colors.redAccent,
                                      ),
                                      tooltip: 'Excluir',
                                      onPressed: () =>
                                          _removerEvento(turma, doc.id),
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
    );
  }
}
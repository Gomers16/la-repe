import 'dart:math';
import 'package:flutter/material.dart';
import 'package:la_repe/data/repositories/collection_repository.dart';
import 'package:la_repe/data/repositories/user_repository.dart';
import 'package:la_repe/models/models.dart';

class AlbumState extends ChangeNotifier {

  final UserRepository _userRepo;
  final CollectionRepository _collectionRepo;

  AlbumState({
    required UserRepository userRepo,
    required CollectionRepository collectionRepo,
  })  : _userRepo = userRepo,
        _collectionRepo = collectionRepo {
    _initializeStickers();
    _initializeMockUsers();
  }

  // Carga datos persistidos. Llamar una vez desde main() antes de runApp().
  Future<void> initialize() async {
    final savedUser = await _userRepo.loadUser();
    final savedCollection = await _collectionRepo.loadCollection();

    _currentUser = savedUser;
    _userCollection
      ..clear()
      ..addAll(savedCollection);

    _recalculateMatches();
    notifyListeners();
  }

  // ─── Estado ────────────────────────────────────────────────────────────────

  AppUser? _currentUser;
  AppUser? get currentUser => _currentUser;

  bool get isOnboarded => _currentUser != null;

  final List<Sticker> _allStickers = [];
  List<Sticker> get allStickers => _allStickers;

  final Map<String, UserSticker> _userCollection = {};
  Map<String, UserSticker> get userCollection => _userCollection;

  final List<Sticker> _swipeQueue = [];
  List<Sticker> get swipeQueue => _swipeQueue;

  int _swipeBatchLimit = 50;
  int _swipeIndex = 0;

  int get swipeIndex => _swipeIndex;
  int get swipeBatchLimit => _swipeBatchLimit;

  int swipeSessionCompletas = 0;
  int swipeSessionRepetidas = 0;
  int swipeSessionNecesitadas = 0;

  final List<MockUserCollection> _mockUsers = [];

  List<TradeMatch> _activeMatches = [];
  List<TradeMatch> get activeMatches => _activeMatches;

  // ─── Getters de progreso ───────────────────────────────────────────────────

  int get totalCompletadas =>
      _userCollection.values.where((s) => s.state == StickerState.completa).length;

  int get totalNecesito =>
      _userCollection.values.where((s) => s.state == StickerState.necesito).length;

  int get totalRepetidas =>
      _userCollection.values.where((s) => s.state == StickerState.repetida).length;

  double get progressPercentage {
    final total = _allStickers.where((s) => s.affectsProgressBar).length;
    if (total == 0) return 0.0;
    final completed = _userCollection.values
        .where((us) {
          final sticker = _allStickers.firstWhere(
            (s) => s.id == us.stickerId,
            orElse: () => _nullSticker,
          );
          return us.state == StickerState.completa && sticker.affectsProgressBar;
        })
        .length;
    return (completed / total) * 100;
  }

  // ─── Consultas de colección ────────────────────────────────────────────────

  UserSticker? getUserSticker(String stickerId) => _userCollection[stickerId];

  StickerState? getStickerState(String stickerId) =>
      _userCollection[stickerId]?.state;

  bool isStickerPriority(String stickerId) =>
      _userCollection[stickerId]?.isPriority ?? false;

  // ─── Modificación de colección (escribe en memoria + disco) ───────────────

  void setStickerState(
    String stickerId,
    StickerState newState, {
    bool isPriority = false,
    int quantity = 1,
  }) {
    final sticker = UserSticker(
      stickerId: stickerId,
      state: newState,
      isPriority: isPriority,
      quantity: quantity,
    );
    _userCollection[stickerId] = sticker;
    _collectionRepo.saveSticker(sticker);
    _recalculateMatches();
    notifyListeners();
  }

  void togglePriority(String stickerId) {
    final s = _userCollection[stickerId];
    if (s == null) return;
    final updated = UserSticker(
      stickerId: stickerId,
      state: s.state,
      isPriority: !s.isPriority,
      quantity: s.quantity,
    );
    _userCollection[stickerId] = updated;
    _collectionRepo.saveSticker(updated);
    notifyListeners();
  }

  void updateRepetidaQuantity(String stickerId, int delta) {
    final s = _userCollection[stickerId];
    if (s == null) return;
    final updated = UserSticker(
      stickerId: stickerId,
      state: s.state,
      isPriority: s.isPriority,
      quantity: (s.quantity + delta).clamp(1, 99),
    );
    _userCollection[stickerId] = updated;
    _collectionRepo.saveSticker(updated);
    _recalculateMatches();
    notifyListeners();
  }

  void removeStickerFromCollection(String stickerId) {
    _userCollection.remove(stickerId);
    _collectionRepo.removeSticker(stickerId);
    _recalculateMatches();
    notifyListeners();
  }

  // ─── Sesión Swipe ──────────────────────────────────────────────────────────

  // unclassifiedOnly = true → solo muestra figuritas que el usuario aún no clasificó
  void startNewSwipeSession(int size, {bool unclassifiedOnly = true}) {
    final random = Random();
    _swipeQueue.clear();
    _swipeIndex = 0;
    swipeSessionCompletas = 0;
    swipeSessionRepetidas = 0;
    swipeSessionNecesitadas = 0;

    final source = unclassifiedOnly
        ? _allStickers.where((s) => !_userCollection.containsKey(s.id)).toList()
        : List<Sticker>.from(_allStickers);
    source.shuffle(random);
    _swipeQueue.addAll(source.take(size));
    notifyListeners();
  }

  TradeMatch? checkQuickMatchFor(String stickerId) {
    final myNeedsThis = _userCollection[stickerId]?.state == StickerState.necesito;
    if (!myNeedsThis) return null;

    for (final user in _mockUsers) {
      if (user.repetidas.contains(stickerId)) {
        return TradeMatch(
          id: user.userName.replaceAll(' ', '_'),
          userName: user.userName,
          whatsapp: user.whatsapp,
          city: user.city,
          distanceKm: user.distanceKm,
          compatibilityPercent: 90,
          stickersIHaveHeNeeds: [],
          stickersHeHasINeed: [stickerId],
        );
      }
    }
    return null;
  }

  void advanceSwipe(StickerState action, {int qty = 1}) {
    if (_swipeIndex >= _swipeQueue.length) return;
    final sticker = _swipeQueue[_swipeIndex];

    switch (action) {
      case StickerState.completa:
        swipeSessionCompletas++;
        setStickerState(sticker.id, StickerState.completa);
        break;
      case StickerState.necesito:
        swipeSessionNecesitadas++;
        setStickerState(sticker.id, StickerState.necesito);
        break;
      case StickerState.repetida:
        swipeSessionRepetidas++;
        setStickerState(sticker.id, StickerState.repetida, quantity: qty);
        break;
    }

    _swipeIndex++;
    notifyListeners();
  }

  // ─── Auth ──────────────────────────────────────────────────────────────────

  void loginOrRegister(
    String name,
    String city,
    String country,
    String whatsapp,
  ) {
    final user = AppUser(name: name, city: city, country: country, whatsapp: whatsapp);
    _currentUser = user;
    _userRepo.saveUser(user);
    notifyListeners();
  }

  void logout() {
    _currentUser = null;
    _userCollection.clear();
    _userRepo.clearUser();
    _collectionRepo.clearCollection();
    _recalculateMatches();
    notifyListeners();
  }

  // ─── Inicialización del catálogo ───────────────────────────────────────────

  void _initializeStickers() {

    for (int i = 1; i <= 20; i++) {
      _allStickers.add(
        Sticker(
          id: 'S-$i',
          number: 'S-$i',
          name: _getStadiumName(i),
          teamName: 'Sedes y Estadios',
          categoryName: 'Escudos y Sedes',
          rarity: StickerRarity.especial,
          difficultyIndex: 3,
        ),
      );
    }

    final countries = [
      'Colombia', 'Argentina', 'Brasil', 'Uruguay', 'Ecuador',
      'Chile', 'Paraguay', 'Perú', 'Alemania', 'Francia',
      'España', 'Italia', 'Inglaterra', 'Portugal', 'Holanda',
      'Bélgica', 'México', 'Estados Unidos', 'Canadá', 'Costa Rica',
      'Panamá', 'Japón', 'Corea del Sur', 'Australia', 'Arabia Saudita',
      'Irán', 'Marruecos', 'Senegal', 'Túnez', 'Camerún',
      'Ghana', 'Croacia', 'Suiza', 'Dinamarca', 'Polonia',
      'Serbia', 'Gales', 'Suecia', 'Ucrania', 'Austria',
      'Turquía', 'Egipto', 'Nigeria', 'Argelia', 'Costa de Marfil',
      'Sudáfrica', 'Catar', 'Honduras',
    ];

    for (final country in countries) {
      final code = country
          .substring(0, min(country.length, 3))
          .toUpperCase();

      for (int i = 1; i <= 20; i++) {
        final isEscudo = i == 1;
        final isTop = i == 10;

        final rarity = (isEscudo || isTop)
            ? StickerRarity.especial
            : StickerRarity.comun;

        _allStickers.add(
          Sticker(
            id: '$code-$i',
            number: '$code-$i',
            name: isEscudo
                ? 'Escudo $country'
                : _getPlayerName(country, i),
            teamName: country,
            categoryName: isEscudo ? 'Escudos' : 'Regulares',
            rarity: rarity,
            difficultyIndex: isEscudo ? 4 : (isTop ? 5 : 1),
          ),
        );
      }
    }

    for (int i = 1; i <= 14; i++) {
      _allStickers.add(
        Sticker(
          id: 'CC-$i',
          number: 'CC-$i',
          name: 'Coca-Cola Promo #$i',
          teamName: 'Sección Coca-Cola',
          categoryName: 'Coca-Cola',
          rarity: StickerRarity.especial,
          difficultyIndex: 4,
        ),
      );
    }

    final extras = [
      'Lionel Messi (Extra)',
      'Cristiano Ronaldo (Extra)',
      'Neymar Jr (Extra)',
      'Kylian Mbappé (Extra)',
      'Erling Haaland (Extra)',
      'Luis Díaz (Extra)',
      'James Rodríguez (Extra)',
      'Vinícius Jr (Extra)',
      'Luka Modrić (Extra)',
      'Robert Lewandowski (Extra)',
      'Kevin De Bruyne (Extra)',
      'Mohamed Salah (Extra)',
      'Harry Kane (Extra)',
      'Antoine Griezmann (Extra)',
      'Son Heung-min (Extra)',
      'Jude Bellingham (Extra)',
      'Federico Valverde (Extra)',
      'Pedri (Extra)',
      'Lautaro Martínez (Extra)',
      'Bukayo Saka (Extra)',
    ];

    for (int i = 1; i <= 20; i++) {
      for (final variant in [
        StickerRarity.comun,
        StickerRarity.paralelaBronce,
        StickerRarity.paralelaPlata,
        StickerRarity.paralelaOro,
        StickerRarity.especial,
      ]) {
        String suffix = '';
        String label = '';
        int difficulty = 3;

        switch (variant) {
          case StickerRarity.comun:
            suffix = 'C';
            label = '(Base)';
            break;
          case StickerRarity.paralelaBronce:
            suffix = 'B';
            label = '(Bronce)';
            difficulty = 4;
            break;
          case StickerRarity.paralelaPlata:
            suffix = 'S';
            label = '(Plata)';
            difficulty = 4;
            break;
          case StickerRarity.paralelaOro:
            suffix = 'G';
            label = '(Oro)';
            difficulty = 5;
            break;
          case StickerRarity.especial:
            suffix = 'E';
            label = '(Especial)';
            difficulty = 5;
            break;
        }

        _allStickers.add(
          Sticker(
            id: 'EXTRA-$i-$suffix',
            number: 'EXTRA-$i',
            name: '${extras[i - 1]} $label',
            teamName: 'Extra Stickers',
            categoryName: 'Extra Stickers',
            rarity: variant,
            difficultyIndex: difficulty,
          ),
        );
      }
    }
  }

  void _initializeMockUsers() {
    final random = Random();
    final allIds = _allStickers.map((s) => s.id).toList();

    final names = [
      'Carlos Pérez', 'Andrés Gómez', 'María López', 'Juan Rodríguez',
      'Laura Martínez', 'Diego Sánchez', 'Valentina Torres', 'Sebastián Díaz',
    ];

    final cities = ['Ibagué', 'Bogotá', 'Medellín', 'Cali', 'Bucaramanga'];

    for (int i = 0; i < names.length; i++) {
      final shuffled = List<String>.from(allIds)..shuffle(random);
      final split = (shuffled.length * 0.3).round();

      _mockUsers.add(
        MockUserCollection(
          userName: names[i],
          whatsapp: '+573${100000000 + random.nextInt(99999999)}',
          city: cities[random.nextInt(cities.length)],
          distanceKm: (random.nextDouble() * 50).roundToDouble(),
          repetidas: shuffled.sublist(0, split).toSet(),
          necesitas: shuffled.sublist(split, split * 2).toSet(),
        ),
      );
    }
  }

  void _recalculateMatches() {
    final List<TradeMatch> newMatches = [];

    final myNeeds = <String>{};
    final myRepe = <String>{};

    _userCollection.forEach((id, value) {
      if (value.state == StickerState.necesito) myNeeds.add(id);
      if (value.state == StickerState.repetida && value.quantity > 0) myRepe.add(id);
    });

    for (final user in _mockUsers) {
      final give = myRepe.intersection(user.necesitas).toList();
      final receive = user.repetidas.intersection(myNeeds).toList();

      if (give.isEmpty && receive.isEmpty) continue;

      final mutual = give.isNotEmpty && receive.isNotEmpty;
      int score = mutual ? 85 : 55;
      score += min(give.length + receive.length, 15);

      newMatches.add(
        TradeMatch(
          id: user.userName.replaceAll(' ', '_'),
          userName: user.userName,
          whatsapp: user.whatsapp,
          city: user.city,
          distanceKm: user.distanceKm,
          compatibilityPercent: score,
          stickersIHaveHeNeeds: give,
          stickersHeHasINeed: receive,
        ),
      );
    }

    newMatches.sort((a, b) {
      final c = b.compatibilityPercent.compareTo(a.compatibilityPercent);
      if (c != 0) return c;
      return a.distanceKm.compareTo(b.distanceKm);
    });

    _activeMatches = newMatches;
  }

  String _getStadiumName(int i) => 'Estadio $i';
  String _getPlayerName(String country, int index) => '$country Jugador $index';

  static const Sticker _nullSticker = Sticker(
    id: '',
    number: '',
    name: 'Desconocido',
    teamName: '',
    categoryName: '',
  );
}

class MockUserCollection {
  final String userName;
  final String whatsapp;
  final String city;
  final double distanceKm;
  final Set<String> repetidas;
  final Set<String> necesitas;

  MockUserCollection({
    required this.userName,
    required this.whatsapp,
    required this.city,
    required this.distanceKm,
    required this.repetidas,
    required this.necesitas,
  });
}

class AlbumStateProvider extends InheritedNotifier<AlbumState> {
  const AlbumStateProvider({
    super.key,
    required super.notifier,
    required super.child,
  });

  static AlbumState of(BuildContext context) {
    final provider =
        context.dependOnInheritedWidgetOfExactType<AlbumStateProvider>();
    assert(provider != null, 'AlbumStateProvider no encontrado');
    return provider!.notifier!;
  }
}

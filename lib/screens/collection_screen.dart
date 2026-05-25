import 'package:flutter/material.dart';
import 'package:la_repe/models/models.dart';
import 'package:la_repe/services/supabase_service.dart';
import 'package:la_repe/state/album_state.dart';
import 'package:la_repe/theme/theme.dart';

class CollectionScreen extends StatefulWidget {
  const CollectionScreen({super.key});

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  String _selectedSection = 'Mundial';
  String _selectedTeam = 'Colombia';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _activeFilter = 'Todas';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> _getTeamsList(AlbumState state) {
    final Set<String> teams = {};
    for (final s in state.allStickers) {
      if (s.affectsProgressBar) {
        teams.add(s.teamName);
      }
    }
    return teams.toList();
  }

  @override
  Widget build(BuildContext context) {
    final state = AlbumStateProvider.of(context);

    final teams = _getTeamsList(state);
    if (!teams.contains(_selectedTeam) && teams.isNotEmpty) {
      _selectedTeam = teams.first;
    }

    List<Sticker> displayedStickers = state.allStickers.where((sticker) {
      if (_selectedSection == 'Mundial') {
        if (!sticker.affectsProgressBar || sticker.teamName != _selectedTeam) {
          return false;
        }
      } else if (_selectedSection == 'Coca-Cola') {
        if (!sticker.isCocaCola) return false;
      } else if (_selectedSection == 'Extra Stickers') {
        if (!sticker.isExtraSticker) return false;
      }

      if (_searchQuery.isNotEmpty) {
        final matchesNum = sticker.number.toLowerCase().contains(_searchQuery.toLowerCase());
        final matchesName = sticker.name.toLowerCase().contains(_searchQuery.toLowerCase());
        if (!matchesNum && !matchesName) return false;
      }

      final userSticker = state.getUserSticker(sticker.id);
      if (_activeFilter == 'Faltantes') {
        return userSticker?.state == StickerState.necesito;
      } else if (_activeFilter == 'Repetidas') {
        return userSticker?.state == StickerState.repetida;
      } else if (_activeFilter == 'Prioridades') {
        return userSticker?.state == StickerState.necesito && (userSticker?.isPriority ?? false);
      }

      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Colección'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => _showLegendDialog(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              color: AppTheme.surface,
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildSectionTab('Mundial'),
                  _buildSectionTab('Coca-Cola'),
                  _buildSectionTab('Extra Stickers'),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    onChanged: (val) => setState(() => _searchQuery = val),
                    decoration: InputDecoration(
                      hintText: 'Buscar por número o nombre (ej: COL-10)...',
                      prefixIcon: const Icon(Icons.search, color: Colors.white38),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.white38),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('Todas'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Faltantes'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Repetidas'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Prioridades'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            if (_selectedSection == 'Mundial') ...[
              Container(
                height: 45,
                margin: const EdgeInsets.only(bottom: 8),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: teams.length,
                  itemBuilder: (context, index) {
                    final teamName = teams[index];
                    final isSelected = teamName == _selectedTeam;

                    final teamStickers = state.allStickers.where((s) => s.teamName == teamName).toList();
                    final completeCount = teamStickers
                        .where((s) => state.getStickerState(s.id) == StickerState.completa)
                        .length;

                    return GestureDetector(
                      onTap: () => setState(() => _selectedTeam = teamName),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.primaryGold : AppTheme.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Row(
                          children: [
                            Text(
                              teamName,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? AppTheme.background : Colors.white70,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.background.withValues(alpha: 0.15)
                                    : AppTheme.surfaceLight,
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '$completeCount/${teamStickers.length}',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? AppTheme.background : Colors.white60,
                                ),
                              ),
                            )
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],

            Expanded(
              child: displayedStickers.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.layers_clear_outlined, size: 60, color: Colors.white38),
                          const SizedBox(height: 12),
                          const Text(
                            'No se encontraron figuritas',
                            style: TextStyle(fontSize: 16, color: Colors.white60),
                          ),
                        ],
                      ),
                    )
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth;
                        final crossAxisCount = width > 700 ? 8 : (width > 480 ? 6 : 4);
                        return GridView.builder(
                      padding: const EdgeInsets.all(12),
                      physics: const BouncingScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 0.82,
                      ),
                      itemCount: displayedStickers.length,
                      itemBuilder: (context, index) {
                        final sticker = displayedStickers[index];
                        final userSticker = state.getUserSticker(sticker.id);
                        final stickerState = userSticker?.state;
                        final isPriority = userSticker?.isPriority ?? false;

                        Color borderAndBadgeColor = Colors.transparent;
                        String badgeText = '';
                        Color cardColor = AppTheme.surface;

                        if (stickerState == StickerState.completa) {
                          borderAndBadgeColor = AppTheme.completedRed;
                          cardColor = AppTheme.completedRed.withValues(alpha: 0.08);
                        } else if (stickerState == StickerState.necesito) {
                          borderAndBadgeColor = AppTheme.neededGreen;
                          cardColor = AppTheme.neededGreen.withValues(alpha: 0.08);
                          if (isPriority) badgeText = '⭐';
                        } else if (stickerState == StickerState.repetida) {
                          borderAndBadgeColor = AppTheme.repeatedYellow;
                          cardColor = AppTheme.repeatedYellow.withValues(alpha: 0.08);
                          badgeText = 'x${userSticker?.quantity}';
                        }

                        return GestureDetector(
                          onTap: () => _showStickerEditSheet(context, sticker, state),
                          child: Stack(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: cardColor,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: borderAndBadgeColor != Colors.transparent
                                        ? borderAndBadgeColor
                                        : Colors.white10,
                                    width: borderAndBadgeColor != Colors.transparent ? 2.0 : 1.0,
                                  ),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      sticker.id.startsWith('EXTRA')
                                          ? sticker.id.split('-')[1]
                                          : sticker.number,
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w900, // era FontWeight.black
                                        color: borderAndBadgeColor != Colors.transparent
                                            ? borderAndBadgeColor
                                            : Colors.white70,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                                      child: Text(
                                        sticker.name,
                                        style: const TextStyle(fontSize: 10, color: Colors.white38),
                                        textAlign: TextAlign.center,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (sticker.isExtraSticker)
                                Positioned(
                                  bottom: 4,
                                  right: 4,
                                  child: Icon(
                                    Icons.star_rounded,
                                    size: 10,
                                    color: sticker.rarity == StickerRarity.paralelaOro
                                        ? Colors.amber
                                        : (sticker.rarity == StickerRarity.paralelaPlata
                                            ? Colors.grey[400]
                                            : (sticker.rarity == StickerRarity.paralelaBronce
                                                ? Colors.brown[300]
                                                : Colors.white24)),
                                  ),
                                ),
                              if (badgeText.isNotEmpty)
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: borderAndBadgeColor,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      badgeText,
                                      style: const TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.background,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTab(String title) {
    final isSelected = _selectedSection == title;
    return GestureDetector(
      onTap: () => setState(() {
        _selectedSection = title;
        _activeFilter = 'Todas';
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? AppTheme.primaryGold : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? AppTheme.primaryGold : Colors.white60,
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChip(String filterName) {
    final isSelected = _activeFilter == filterName;
    return GestureDetector(
      onTap: () => setState(() => _activeFilter = filterName),
      child: Chip(
        label: Text(
          filterName,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? AppTheme.background : Colors.white70,
          ),
        ),
        backgroundColor: isSelected ? AppTheme.primaryGold : AppTheme.surfaceLight,
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
    );
  }

  // Escribe el estado en Supabase en background (fire & forget).
  // Hive ya se actualizó vía AlbumState — Supabase es el espejo remoto.
  void _syncSticker(String stickerId, StickerState newState, {int cantidad = 1}) {
    final userId     = SupabaseService.currentUserId;
    final figuritaId = SupabaseService.getFiguritaId(stickerId);
    if (userId == null || figuritaId == null) return;
    final estadoStr = switch (newState) {
      StickerState.completa => 'completa',
      StickerState.necesito => 'necesito',
      StickerState.repetida => 'repetida',
    };
    SupabaseService.upsertFigurita(
      userId: userId, figuritaId: figuritaId,
      estado: estadoStr, cantidad: cantidad,
    ).catchError((_) {});
  }

  void _showStickerEditSheet(BuildContext context, Sticker sticker, AlbumState state) {
    final userSticker = state.getUserSticker(sticker.id);
    final initialQty = userSticker?.quantity ?? 1;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final currentStState = state.getStickerState(sticker.id);
            final currentPriority = state.isStickerPriority(sticker.id);
            final currentQty = state.getUserSticker(sticker.id)?.quantity ?? initialQty;

            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sticker.number,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w900, // era FontWeight.black
                              color: AppTheme.primaryGold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            sticker.name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${sticker.teamName} • ${sticker.rarityLabel}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.white54, // era Colors.white50
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            'DIFICULTAD',
                            style: TextStyle(fontSize: 10, color: Colors.white38, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: List.generate(5, (index) {
                              return Icon(
                                Icons.local_fire_department,
                                size: 16,
                                color: index < sticker.difficultyIndex
                                    ? Colors.orange
                                    : Colors.white10,
                              );
                            }),
                          )
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 24),

                  const Text(
                    'ESTADO DE LA FIGURITA',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white54, // era Colors.white50
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _buildActionBtn(
                          title: 'La tengo',
                          color: AppTheme.completedRed,
                          isSelected: currentStState == StickerState.completa,
                          onTap: () {
                            state.setStickerState(sticker.id, StickerState.completa);
                            _syncSticker(sticker.id, StickerState.completa);
                            setSheetState(() {});
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildActionBtn(
                          title: 'La necesito',
                          color: AppTheme.neededGreen,
                          isSelected: currentStState == StickerState.necesito,
                          onTap: () {
                            state.setStickerState(sticker.id, StickerState.necesito, isPriority: currentPriority);
                            _syncSticker(sticker.id, StickerState.necesito);
                            setSheetState(() {});
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildActionBtn(
                          title: 'Tengo repe',
                          color: AppTheme.repeatedYellow,
                          isSelected: currentStState == StickerState.repetida,
                          onTap: () {
                            state.setStickerState(sticker.id, StickerState.repetida, quantity: currentQty);
                            _syncSticker(sticker.id, StickerState.repetida, cantidad: currentQty);
                            setSheetState(() {});
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  if (currentStState == StickerState.necesito) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.star, color: Colors.amber, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Marcar como prioridad',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Switch(
                          value: currentPriority,
                          activeThumbColor: AppTheme.primaryGold,
                          onChanged: (val) {
                            state.togglePriority(sticker.id);
                            setSheetState(() {});
                          },
                        )
                      ],
                    ),
                  ] else if (currentStState == StickerState.repetida) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.copy_rounded, color: AppTheme.primaryGold, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Cantidad de repetidas',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: Colors.white70),
                              onPressed: () {
                                if (currentQty > 1) {
                                  state.updateRepetidaQuantity(sticker.id, -1);
                                  setSheetState(() {});
                                }
                              },
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceLight,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$currentQty',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline, color: AppTheme.primaryGold),
                              onPressed: () {
                                state.updateRepetidaQuantity(sticker.id, 1);
                                setSheetState(() {});
                              },
                            ),
                          ],
                        )
                      ],
                    ),
                  ],

                  const SizedBox(height: 24),

                  if (currentStState != null)
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () {
                          state.removeStickerFromCollection(sticker.id);
                          Navigator.pop(context);
                        },
                        child: const Text(
                          'Eliminar de mi colección',
                          style: TextStyle(
                            color: Colors.white54, // era Colors.white38 — ajusta a gusto
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildActionBtn({
    required String title,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? color : AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.white10,
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            
            color: isSelected ? AppTheme.background : Colors.white70,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  void _showLegendDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Estados de Láminas'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLegendItem(color: AppTheme.completedRed, label: 'La tengo (Completa)'),
            const SizedBox(height: 8),
            _buildLegendItem(color: AppTheme.neededGreen, label: 'La necesito (Faltante)'),
            const SizedBox(height: 8),
            _buildLegendItem(color: AppTheme.repeatedYellow, label: 'Tengo repe (Repetida)'),
            const SizedBox(height: 16),
            const Divider(color: Colors.white10),
            const SizedBox(height: 8),
            const Row(
              children: [
                Icon(Icons.star, color: Colors.amber, size: 20),
                SizedBox(width: 12),
                Text('Marcada como Prioridad', style: TextStyle(fontSize: 14)),
              ],
            )
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar', style: TextStyle(color: AppTheme.primaryGold)),
          )
        ],
      ),
    );
  }

  Widget _buildLegendItem({required Color color, required String label}) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            border: Border.all(color: color, width: 2),
            borderRadius: BorderRadius.circular(6),
          ),
        ),
        const SizedBox(width: 12),
        Text(label, style: const TextStyle(fontSize: 14)),
      ],
    );
  }
}
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'core.dart';

// =============================================================================
// COLOR CONSTANTS — Custom palette
// =============================================================================
/// A centralized location for all the custom colors used in the app.
/// This ensures consistency and makes it easy to change the theme later.
class AppColors {
  static const Color black = Color(0xFF0A0A0A);         // Deep background
  static const Color surface = Color(0xFF1C1A17);       // Primary card surface
  static const Color surfaceLight = Color(0xFF252320);  // Slightly lighter for inputs
  static const Color taupe = Color(0xFFA89F91);         // Muted text and borders
  static const Color sage = Color(0xFFBDB98A);          // Gentle accent for neutral chips
  static const Color cream = Color(0xFFD8D4B8);         // Primary text color
  static const Color blue = Color(0xFF6699CC);          // Primary branding/Healthy stock
  static const Color blueLight = Color(0xFF88B4DD);     // Gradient endpoint for blue
  static const Color orange = Color(0xFFF9A825);        // Warning/Low stock
  static const Color orangeLight = Color(0xFFFFCA28);   // Gradient endpoint for orange
}

// =============================================================================
// REUSABLE GRADIENT APP BAR
// =============================================================================
/// A custom AppBar implementation that provides a gradient background.
/// It implements PreferredSizeWidget so Flutter knows how tall to draw it.
class _GradientAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;

  const _GradientAppBar({required this.title, this.showBackButton = false});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        // Gives the header a subtle dark gradient instead of a flat color
        gradient: LinearGradient(
          colors: [Color(0xFF151310), Color(0xFF1C1A17)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // If we are on a main screen (no back button), show the app logo/icon
            if (!showBackButton)
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.blue, AppColors.blueLight],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.inventory_2, size: 20, color: AppColors.black),
              ),
            if (!showBackButton) const SizedBox(width: 10),
            Text(title),
          ],
        ),
        // If showBackButton is true, we render a custom styled back button.
        // Otherwise, it defaults to null (no leading widget).
        leading: showBackButton
            ? IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.taupe.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new, size: 18, color: AppColors.cream),
                ),
                onPressed: () => Navigator.pop(context),
              )
            : null,
      ),
    );
  }
}

// =============================================================================
// HOME SCREEN (NAVIGATION SHELL)
// =============================================================================
/// The HomeScreen acts as the main container for the app.
/// It holds the BottomNavigationBar and switches between the two main tabs.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Keeps track of which tab is currently selected
  int _currentIndex = 0;
  
  // The two actual screens that can be displayed
  final List<Widget> _screens = const [
    StockListScreen(),
    MovementLogScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AnimatedSwitcher provides a nice cross-fade transition when changing tabs
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _screens[_currentIndex],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: AppColors.taupe.withValues(alpha: 0.1),
              width: 1, // Subtle top border to separate nav from content
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            // Updating the state triggers a rebuild, switching the visible screen
            setState(() {
              _currentIndex = index;
            });
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined),
              selectedIcon: Icon(Icons.inventory_2),
              label: 'Stock List',
            ),
            NavigationDestination(
              icon: Icon(Icons.timeline_outlined),
              selectedIcon: Icon(Icons.timeline),
              label: 'Activity',
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// DASHBOARD SUMMARY CARDS
// =============================================================================
/// A row of three cards displayed at the top of the Stock List.
/// Shows aggregate data: Total Items, Low Stock count, and Total Quantity.
class _SummaryCards extends StatelessWidget {
  const _SummaryCards();

  @override
  Widget build(BuildContext context) {
    // We use a Consumer to listen to the StockProvider.
    // Whenever inventory changes, these cards will automatically recalculate.
    return Consumer<StockProvider>(
      builder: (context, provider, _) {
        final totalItems = provider.items.length;
        // Count how many items are currently below their reorder threshold
        final lowStockItems = provider.items.where((i) => i.isLowStock).length;
        // Sum up the total quantity across all items using a fold (reduce)
        final totalQty = provider.items.fold<int>(0, (sum, i) => sum + i.currentQuantity);

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            children: [
              _buildSummaryCard(
                context,
                icon: Icons.category_outlined,
                label: 'Total Items',
                value: '$totalItems',
                gradient: const [AppColors.blue, AppColors.blueLight],
              ),
              const SizedBox(width: 10),
              _buildSummaryCard(
                context,
                icon: Icons.warning_amber_rounded,
                label: 'Low Stock',
                value: '$lowStockItems',
                // Turn the card orange if there are warnings, otherwise a neutral sage
                gradient: lowStockItems > 0
                    ? const [AppColors.orange, AppColors.orangeLight]
                    : const [AppColors.sage, Color(0xFFD4D0A8)],
              ),
              const SizedBox(width: 10),
              _buildSummaryCard(
                context,
                icon: Icons.all_inbox_outlined,
                label: 'Total Qty',
                value: '$totalQty',
                gradient: const [AppColors.taupe, AppColors.cream],
              ),
            ],
          ),
        );
      },
    );
  }

  /// Helper method to build a single summary card with a gradient background
  Widget _buildSummaryCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required List<Color> gradient,
  }) {
    return Expanded( // Ensures all three cards take up equal horizontal space
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          // Very transparent gradient for a subtle glass effect
          gradient: LinearGradient(
            colors: [
              gradient[0].withValues(alpha: 0.15),
              gradient[1].withValues(alpha: 0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: gradient[0].withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: gradient[0], size: 22),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: gradient[0],
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.taupe.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// MAIN INVENTORY LIST SCREEN
// =============================================================================
/// Displays the summary cards and the scrollable list of all inventory items.
class StockListScreen extends StatelessWidget {
  const StockListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const _GradientAppBar(title: 'StockWatch'),
      // Consumer listens for changes from StockProvider
      body: Consumer<StockProvider>(
        builder: (context, provider, child) {
          // 1. Show a loading spinner if data is still being fetched from disk
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.blue),
            );
          }

          // 2. Show an empty state message if there are no items
          if (provider.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined,
                      size: 64, color: AppColors.taupe.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  Text(
                    'No stock items found.',
                    style: TextStyle(color: AppColors.taupe.withValues(alpha: 0.6), fontSize: 16),
                  ),
                ],
              ),
            );
          }

          // 3. Show the actual data
          return Column(
            children: [
              const _SummaryCards(),
              // Section header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Row(
                  children: [
                    Text(
                      'INVENTORY',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                        color: AppColors.taupe.withValues(alpha: 0.5),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${provider.items.length} items',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.taupe.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              ),
              // The scrollable list of items
              Expanded(
                child: ListView.builder(
                  itemCount: provider.items.length,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  itemBuilder: (context, index) {
                    final item = provider.items[index];
                    return _StockItemCard(item: item, index: index);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// =============================================================================
// STOCK ITEM CARD WIDGET
// =============================================================================
/// A highly visual card representing a single inventory item in the list.
class _StockItemCard extends StatelessWidget {
  final StockItem item;
  final int index;

  const _StockItemCard({required this.item, required this.index});

  /// Helper method to assign an appropriate icon based on the category string.
  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'laptops':
        return Icons.laptop_mac;
      case 'accessories':
        return Icons.mouse;
      case 'monitors':
        return Icons.monitor;
      case 'furniture':
        return Icons.chair;
      case 'components':
        return Icons.memory;
      default:
        return Icons.inventory_2;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine the color theme for this card based on stock levels
    final statusColor = item.isLowStock ? AppColors.orange : AppColors.blue;
    
    // Calculate how full the "progress bar" should be.
    // It tops out (1.0) when stock is 3x the reorder threshold.
    final progress = item.reorderThreshold > 0
        ? (item.currentQuantity / (item.reorderThreshold * 3)).clamp(0.0, 1.0)
        : 1.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        // InkWell provides the Material ripple effect when tapped
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Navigate to the ItemDetailScreen when tapped
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (_, __, ___) => ItemDetailScreen(item: item),
                // Custom transition: Slide in from the right edge of the screen
                transitionsBuilder: (_, animation, __, child) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(1.0, 0.0),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    )),
                    child: child,
                  );
                },
                transitionDuration: const Duration(milliseconds: 350),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              // The border turns orange if stock is low
              border: Border.all(
                color: item.isLowStock
                    ? AppColors.orange.withValues(alpha: 0.25)
                    : AppColors.taupe.withValues(alpha: 0.08),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // 1. Category Icon (Left side)
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        statusColor.withValues(alpha: 0.2),
                        statusColor.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getCategoryIcon(item.category),
                    color: statusColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                
                // 2. Middle column: Name, Badges, and Progress Bar
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: AppColors.cream,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // We use a Wrap widget here instead of a Row to prevent overflow 
                      // if the category name is very long. It will wrap to the next line.
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          // Category Label Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.sage.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              item.category,
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.sage.withValues(alpha: 0.8),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          // Optional "Low Stock" Warning Badge
                          if (item.isLowStock)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.orange.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.warning_amber_rounded,
                                      size: 12, color: AppColors.orange),
                                  SizedBox(width: 4),
                                  Text(
                                    'Low Stock',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.orange,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Visual indicator of stock health
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 4,
                          backgroundColor: AppColors.taupe.withValues(alpha: 0.08),
                          valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                
                // 3. Current Quantity display (Right side)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${item.currentQuantity}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: statusColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'min ${item.reorderThreshold}',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.taupe.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.taupe.withValues(alpha: 0.25),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// ITEM DETAIL SCREEN
// =============================================================================
/// Displays in-depth information about a single item, and allows the user
/// to perform "Stock In" or "Stock Out" transactions.
class ItemDetailScreen extends StatelessWidget {
  final StockItem item; // The item that was clicked to reach this screen

  const ItemDetailScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _GradientAppBar(title: item.name, showBackButton: true),
      // We wrap the body in a Consumer so that when the user adds/removes stock,
      // this screen instantly updates to reflect the new total and new history log.
      body: Consumer<StockProvider>(
        builder: (context, provider, child) {
          // Find the up-to-date version of this item from the provider
          // (in case the quantity just changed).
          final currentItem = provider.items.firstWhere(
            (i) => i.id == item.id,
            orElse: () => item,
          );
          
          // Filter the global movement list down to ONLY movements for this specific item.
          final itemMovements = provider.movements
              .where((m) => m.itemId == currentItem.id)
              .toList();

          return Column(
            children: [
              // The top card showing current stock and action buttons
              _buildItemInfoCard(context, currentItem),
              
              // Movement history header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: Row(
                  children: [
                    Text(
                      'MOVEMENT HISTORY',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                        color: AppColors.taupe.withValues(alpha: 0.5),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${itemMovements.length} records',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.taupe.withValues(alpha: 0.4),
                      ),
                    ),
                  ],
                ),
              ),
              
              // The scrollable list of historical movements for this item
              Expanded(
                child: itemMovements.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history,
                                size: 48, color: AppColors.taupe.withValues(alpha: 0.2)),
                            const SizedBox(height: 12),
                            Text(
                              'No movements recorded yet.',
                              style: TextStyle(
                                color: AppColors.taupe.withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: itemMovements.length,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemBuilder: (context, index) {
                          final movement = itemMovements[index];
                          return _MovementTile(movement: movement);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Builds the large, detailed card at the top of the Item Detail screen.
  Widget _buildItemInfoCard(BuildContext context, StockItem currentItem) {
    final statusColor = currentItem.isLowStock ? AppColors.orange : AppColors.blue;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        // Custom background gradient for the card
        gradient: LinearGradient(
          colors: [
            AppColors.surface,
            statusColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Stock level header (Number and Health indicator)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Current Stock',
                    style: TextStyle(
                      color: AppColors.taupe.withValues(alpha: 0.7),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${currentItem.currentQuantity}',
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w800,
                      color: statusColor,
                      height: 1, // Tight line height for massive text
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      currentItem.isLowStock
                          ? Icons.trending_down_rounded
                          : Icons.trending_up_rounded,
                      color: statusColor,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      currentItem.isLowStock ? 'Low' : 'Healthy',
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 2. Info chips (Category and Reorder limit)
          Row(
            children: [
              _buildInfoChip(Icons.category_outlined, currentItem.category),
              const SizedBox(width: 10),
              _buildInfoChip(
                Icons.notifications_outlined,
                'Reorder at ${currentItem.reorderThreshold}',
              ),
            ],
          ),

          // 3. Exaggerated warning block (Only visible if stock is low)
          if (currentItem.isLowStock) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.orange.withValues(alpha: 0.2),
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: AppColors.orange, size: 20),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Stock is below reorder threshold. Please reorder soon!',
                      style: TextStyle(
                        color: AppColors.orangeLight,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 20),

          // 4. Action buttons (Triggers the IN/OUT dialogs)
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: Icons.add_rounded,
                  label: 'Stock In',
                  colors: const [AppColors.blue, AppColors.blueLight],
                  // When pressed, open the dialog and tell it we are performing an 'IN' action
                  onPressed: () => _showMovementDialog(context, currentItem, 'IN'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionButton(
                  icon: Icons.remove_rounded,
                  label: 'Stock Out',
                  colors: const [AppColors.orange, AppColors.orangeLight],
                  // When pressed, open the dialog and tell it we are performing an 'OUT' action
                  onPressed: () => _showMovementDialog(context, currentItem, 'OUT'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Helper to build a small informational pill/chip
  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.sage.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.sage.withValues(alpha: 0.7)),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.sage.withValues(alpha: 0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Displays the modal pop-up dialogue for entering a quantity to add/remove.
  /// Type is either 'IN' or 'OUT'.
  void _showMovementDialog(BuildContext context, StockItem item, String type) {
    // TextEditingController allows us to read what the user types into the text field.
    final TextEditingController quantityController = TextEditingController();
    
    final isOut = type == 'OUT';
    final accentColor = isOut ? AppColors.orange : AppColors.blue;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isOut ? Icons.remove_rounded : Icons.add_rounded,
                  color: accentColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                isOut ? 'Stock Out' : 'Stock In',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.cream,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min, // Shrink-wrap the height to fit content
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter quantity for ${item.name}',
                style: TextStyle(
                  color: AppColors.taupe.withValues(alpha: 0.7),
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 16),
              // The text input field
              TextField(
                controller: quantityController,
                keyboardType: TextInputType.number, // Show number pad on mobile
                autofocus: true,                    // Auto-select text field on pop-up
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.cream,
                ),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: '0',
                  hintStyle: TextStyle(
                    color: AppColors.taupe.withValues(alpha: 0.3),
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              // Only show the "Available" text if they are removing stock
              if (isOut)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Available: ${item.currentQuantity}',
                    style: TextStyle(
                      color: AppColors.taupe.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
          actions: [
            // Cancel button — simply closes the dialog
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(color: AppColors.taupe.withValues(alpha: 0.6)),
              ),
            ),
            // Confirm button
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: AppColors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                // 1. Read and parse the text input
                final quantityStr = quantityController.text;
                final quantity = int.tryParse(quantityStr);

                // 2. Validate input
                if (quantity != null && quantity > 0) {
                  // Prevent removing more stock than is available
                  if (isOut && quantity > item.currentQuantity) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Cannot remove more than current stock!'),
                      ),
                    );
                    return;
                  }

                  // 3. Access the provider (listen: false because we are in an onPressed callback)
                  // and execute the business logic.
                  Provider.of<StockProvider>(context, listen: false)
                      .recordMovement(item, type, quantity);
                      
                  // 4. Close the dialog
                  Navigator.pop(context);
                } else {
                  // Show error toast if input is invalid (e.g. empty, "abc", "-5")
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a valid positive number.'),
                    ),
                  );
                }
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('Confirm', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        );
      },
    );
  }
}

// =============================================================================
// GRADIENT ACTION BUTTON 
// =============================================================================
/// A custom, highly-styled button used for the Stock In/Out actions.
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final List<Color> colors; // A list of two colors for the gradient
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.colors,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [colors[0].withValues(alpha: 0.2), colors[1].withValues(alpha: 0.08)],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors[0].withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: colors[0], size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: colors[0],
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// MOVEMENT TILE (ROW COMPONENT)
// =============================================================================
/// A reusable list row widget representing a single StockMovement.
/// Used in both the individual Item history and the Global Activity Log.
class _MovementTile extends StatelessWidget {
  final StockMovement movement;

  const _MovementTile({required this.movement});

  @override
  Widget build(BuildContext context) {
    final isOut = movement.type == 'OUT';
    final color = isOut ? AppColors.orange : AppColors.blue;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.taupe.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          // Icon indicating direction (up/down arrow)
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isOut ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          // Action name and formatted date string using the 'intl' package
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOut ? 'Stock Out' : 'Stock In',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.cream,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  DateFormat('MMM d, yyyy • h:mm a').format(movement.timestamp),
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.taupe.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
          // Quantity badge (+15 or -3)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${isOut ? "-" : "+"}${movement.quantity}',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// GLOBAL MOVEMENT LOG SCREEN
// =============================================================================
/// The second main tab in the app.
/// Displays a master list of all transactions across all items.
class MovementLogScreen extends StatelessWidget {
  const MovementLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const _GradientAppBar(title: 'Activity Log'),
      body: Consumer<StockProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.blue),
            );
          }

          if (provider.movements.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.timeline,
                      size: 64, color: AppColors.taupe.withValues(alpha: 0.2)),
                  const SizedBox(height: 16),
                  Text(
                    'No movements recorded yet.',
                    style: TextStyle(
                      color: AppColors.taupe.withValues(alpha: 0.6),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Stock in/out actions will appear here.',
                    style: TextStyle(
                      color: AppColors.taupe.withValues(alpha: 0.4),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            );
          }

          // Build a list of movements
          // Notice that unlike the Item Detail screen, this screen displays the
          // itemName so the user knows WHICH item the transaction was for.
          return ListView.builder(
            itemCount: provider.movements.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final movement = provider.movements[index];
              final isOut = movement.type == 'OUT';
              final color = isOut ? AppColors.orange : AppColors.blue;

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.taupe.withValues(alpha: 0.05)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            color.withValues(alpha: 0.2),
                            color.withValues(alpha: 0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isOut ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                        color: color,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Display the name of the product that was changed
                          Text(
                            movement.itemName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: AppColors.cream,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              // Small "IN" or "OUT" badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  isOut ? 'OUT' : 'IN',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: color,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Short date/time string
                              Text(
                                DateFormat('MMM d, h:mm a')
                                    .format(movement.timestamp),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.taupe.withValues(alpha: 0.5),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Quantity badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${isOut ? "-" : "+"}${movement.quantity}',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          color: color,
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
    );
  }
}

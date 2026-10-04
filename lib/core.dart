import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

// =============================================================================
// DATA MODELS
// =============================================================================

/// The [StockItem] class represents a single product in the inventory.
/// It holds all the metadata and the current stock count for that product.
class StockItem {
  final String id;              // A unique identifier for the item
  final String name;            // The display name of the item (e.g., "MacBook Pro")
  final String category;        // The grouping category (e.g., "Laptops")
  int currentQuantity;          // The current amount in stock. This is mutable.
  final int reorderThreshold;   // The minimum quantity before a "Low Stock" warning is triggered

  StockItem({
    required this.id,
    required this.name,
    required this.category,
    required this.currentQuantity,
    required this.reorderThreshold,
  });

  /// Computed property that checks if the item's stock is critically low.
  /// Used by the UI to change colors (e.g., to orange/red) and show warnings.
  bool get isLowStock => currentQuantity < reorderThreshold;

  /// Converts this object into a Map (dictionary) so it can be encoded into JSON.
  /// This is required to save the item to local storage.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'currentQuantity': currentQuantity,
      'reorderThreshold': reorderThreshold,
    };
  }

  /// A Factory constructor that creates a StockItem from a Map.
  /// This is used when reading data back from local storage (JSON -> Map -> StockItem).
  factory StockItem.fromMap(Map<String, dynamic> map) {
    return StockItem(
      id: map['id'],
      name: map['name'],
      category: map['category'],
      currentQuantity: map['currentQuantity'],
      reorderThreshold: map['reorderThreshold'],
    );
  }
}

/// The [StockMovement] class represents a single transaction or change in inventory.
/// Every time stock is added (IN) or removed (OUT), one of these is created.
class StockMovement {
  final String id;              // A unique ID for this specific transaction
  final String itemId;          // The ID of the item that was changed
  final String itemName;        // The name of the item (saved here so we don't have to look it up later)
  final String type;            // The type of movement: 'IN' or 'OUT'
  final int quantity;           // How many items were added or removed
  final DateTime timestamp;     // The exact date and time the movement occurred

  StockMovement({
    required this.id,
    required this.itemId,
    required this.itemName,
    required this.type,
    required this.quantity,
    required this.timestamp,
  });

  /// Serializes the movement to a Map for JSON storage.
  /// Note: DateTime is converted to an ISO-8601 string so it can be stored as text.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'itemId': itemId,
      'itemName': itemName,
      'type': type,
      'quantity': quantity,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Deserializes a Map back into a StockMovement object.
  factory StockMovement.fromMap(Map<String, dynamic> map) {
    return StockMovement(
      id: map['id'],
      itemId: map['itemId'],
      itemName: map['itemName'],
      type: map['type'],
      quantity: map['quantity'],
      // Parse the string back into a real DateTime object
      timestamp: DateTime.parse(map['timestamp']), 
    );
  }
}

// =============================================================================
// STORAGE SERVICE
// =============================================================================

/// The [StorageService] handles all reading and writing to the device's local disk.
/// It uses the 'shared_preferences' package, which stores data as simple key-value pairs.
class StorageService {
  // Constants for the storage keys to prevent typos
  static const String _itemsKey = 'stock_items';
  static const String _movementsKey = 'stock_movements';

  /// Loads all inventory items from local storage.
  Future<List<StockItem>> getItems() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Retrieve the list of JSON strings.
    final itemsJson = prefs.getStringList(_itemsKey);
    
    // If there's no data (e.g., first time launching the app), load the mock data.
    if (itemsJson == null || itemsJson.isEmpty) {
      return _getInitialItems();
    }
    
    // Convert each JSON string into a Map, then into a StockItem.
    return itemsJson.map((json) => StockItem.fromMap(jsonDecode(json))).toList();
  }

  /// Saves the current list of inventory items to local storage.
  Future<void> saveItems(List<StockItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    // Convert each StockItem to a Map, then to a JSON string.
    final itemsJson = items.map((item) => jsonEncode(item.toMap())).toList();
    // Save the list of strings to disk.
    await prefs.setStringList(_itemsKey, itemsJson);
  }

  /// Loads all transaction history (movements) from local storage.
  Future<List<StockMovement>> getMovements() async {
    final prefs = await SharedPreferences.getInstance();
    final movementsJson = prefs.getStringList(_movementsKey) ?? [];
    return movementsJson.map((json) => StockMovement.fromMap(jsonDecode(json))).toList();
  }

  /// Saves the transaction history to local storage.
  Future<void> saveMovements(List<StockMovement> movements) async {
    final prefs = await SharedPreferences.getInstance();
    final movementsJson = movements.map((m) => jsonEncode(m.toMap())).toList();
    await prefs.setStringList(_movementsKey, movementsJson);
  }

  /// Provides a seed list of mock items for a first-time user.
  List<StockItem> _getInitialItems() {
    return [
      StockItem(id: '1', name: 'MacBook Pro 16"', category: 'Laptops', currentQuantity: 15, reorderThreshold: 5),
      StockItem(id: '2', name: 'Logitech MX Master 3', category: 'Accessories', currentQuantity: 8, reorderThreshold: 10),
      StockItem(id: '3', name: 'Dell UltraSharp 27"', category: 'Monitors', currentQuantity: 3, reorderThreshold: 5),
      StockItem(id: '4', name: 'Ergonomic Office Chair', category: 'Furniture', currentQuantity: 12, reorderThreshold: 10),
      StockItem(id: '5', name: 'Keychron K8 Pro', category: 'Accessories', currentQuantity: 4, reorderThreshold: 5),
      StockItem(id: '6', name: 'Samsung 980 PRO 1TB', category: 'Components', currentQuantity: 20, reorderThreshold: 10),
      StockItem(id: '7', name: 'Herman Miller Aeron', category: 'Furniture', currentQuantity: 2, reorderThreshold: 3),
      StockItem(id: '8', name: 'Apple Magic Trackpad', category: 'Accessories', currentQuantity: 15, reorderThreshold: 5),
      StockItem(id: '9', name: 'ThinkPad X1 Carbon', category: 'Laptops', currentQuantity: 5, reorderThreshold: 2),
      StockItem(id: '10', name: 'Sony WH-1000XM5', category: 'Accessories', currentQuantity: 7, reorderThreshold: 5),
    ];
  }
}

// =============================================================================
// STATE MANAGEMENT (PROVIDER)
// =============================================================================

/// The [StockProvider] acts as the "brain" and single source of truth for the app's data.
/// It extends [ChangeNotifier], which allows it to broadcast updates to the UI
/// whenever the data changes (via the notifyListeners() method).
class StockProvider extends ChangeNotifier {
  final StorageService _storage = StorageService(); // Handles disk I/O
  final Uuid _uuid = const Uuid();                  // For generating unique IDs

  // Private state variables
  List<StockItem> _items = [];
  List<StockMovement> _movements = [];
  bool _isLoading = true;

  // Public getters to allow the UI to read the state safely (read-only access)
  List<StockItem> get items => _items;
  List<StockMovement> get movements => _movements;
  bool get isLoading => _isLoading;

  /// Constructor: As soon as the provider is created, it begins loading data.
  StockProvider() {
    _loadData();
  }

  /// Internal method to load data from disk into memory.
  Future<void> _loadData() async {
    _isLoading = true;
    notifyListeners(); // Tell the UI to show a loading spinner

    _items = await _storage.getItems();
    _movements = await _storage.getMovements();
    
    // Sort the movements so the newest transactions appear at the top of the list.
    _movements.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    _isLoading = false;
    notifyListeners(); // Tell the UI that loading is done, hide spinner, show data
  }

  /// Records a change in inventory (Stock In or Stock Out).
  /// This is the main business logic function of the app.
  Future<void> recordMovement(StockItem item, String type, int quantity) async {
    // 1. Update the local quantity of the item
    if (type == 'IN') {
      item.currentQuantity += quantity;
    } else if (type == 'OUT') {
      // Ensure we don't end up with a negative stock count
      if (item.currentQuantity >= quantity) {
        item.currentQuantity -= quantity;
      } else {
        item.currentQuantity = 0;
      }
    }

    // 2. Create an audit trail record (a StockMovement)
    final movement = StockMovement(
      id: _uuid.v4(),
      itemId: item.id,
      itemName: item.name,
      type: type,
      quantity: quantity,
      timestamp: DateTime.now(),
    );

    // 3. Add the new movement to the top of the list (index 0)
    _movements.insert(0, movement);
    
    // 4. Notify all listening UI widgets that data has changed so they can rebuild
    notifyListeners();

    // 5. Fire-and-forget save to disk to persist the changes
    await _storage.saveItems(_items);
    await _storage.saveMovements(_movements);
  }
}

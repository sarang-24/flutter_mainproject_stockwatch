import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core.dart';
import 'screens.dart';

// -----------------------------------------------------------------------------
// APP ENTRY POINT
// -----------------------------------------------------------------------------
// The main() function is the starting point of the Flutter application.
void main() {
  runApp(
    // We wrap the entire app in a ChangeNotifierProvider.
    // This allows any widget in the widget tree to access the StockProvider
    // and listen for changes in the inventory state (e.g., when stock goes in or out).
    ChangeNotifierProvider(
      create: (context) => StockProvider(),
      child: const StockWatchApp(),
    ),
  );
}

// -----------------------------------------------------------------------------
// MAIN APPLICATION WIDGET
// -----------------------------------------------------------------------------
// StockWatchApp is the root widget of the application.
// It configures the global theme and sets the initial screen (HomeScreen).
class StockWatchApp extends StatelessWidget {
  const StockWatchApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // The title of the app (used by the OS task manager)
      title: 'StockWatch',
      
      // Hides the "DEBUG" banner in the top right corner
      debugShowCheckedModeBanner: false,
      
      // -----------------------------------------------------------------------
      // GLOBAL THEME CONFIGURATION
      // -----------------------------------------------------------------------
      // We define a custom, consistent color scheme and component styles
      // that will be applied automatically throughout the entire app.
      theme: ThemeData(
        // Opt-in to the latest Material Design 3 features
        useMaterial3: true,
        
        // Force a dark mode aesthetic
        brightness: Brightness.dark,
        
        // Define the core color palette
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF6699CC),       // Primary accent (Blue)
          secondary: const Color(0xFFF9A825),     // Secondary accent (Orange)
          surface: const Color(0xFF1C1A17),       // Dark warm surface color (Cards/Dialogs)
          onSurface: const Color(0xFFD8D4B8),     // Default text color (Cream)
          error: const Color(0xFFF9A825),         // Error/Warning color (Orange)
          primaryContainer: const Color(0xFF252320),
          secondaryContainer: const Color(0xFF6699CC).withValues(alpha: 0.15),
        ),
        
        // Main background color for all screens (Black)
        scaffoldBackgroundColor: const Color(0xFF0A0A0A), 
        
        // Custom styling for the AppBar (Top navigation header)
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,    // We use a custom gradient behind it
          elevation: 0,                           // Flat look, no drop shadow
          centerTitle: true,                      // Title centered in the header
          titleTextStyle: TextStyle(
            color: Color(0xFFD8D4B8),             // Cream text
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        
        // Custom styling for all Cards (used for inventory items)
        cardTheme: CardThemeData(
          color: const Color(0xFF1C1A17),         // Dark warm surface
          elevation: 8,                           // Drop shadow intensity
          shadowColor: Colors.black45,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16), // Rounded corners
          ),
        ),
        
        // Custom styling for the Bottom Navigation Bar
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: const Color(0xFF121110),
          indicatorColor: const Color(0xFF6699CC).withValues(alpha: 0.2), // Highlight for selected tab
          
          // Dynamically change text style based on whether the tab is selected
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                color: Color(0xFF6699CC), // Blue when selected
                fontWeight: FontWeight.w600,
                fontSize: 12,
              );
            }
            return const TextStyle(
              color: Color(0xFFA89F91),   // Taupe when unselected
              fontSize: 12,
            );
          }),
          
          // Dynamically change icon color/size based on whether the tab is selected
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: Color(0xFF6699CC), size: 26);
            }
            return const IconThemeData(color: Color(0xFFA89F91), size: 24);
          }),
        ),
        
        // Custom styling for Elevated Buttons
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            textStyle: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        
        // Custom styling for Pop-up Dialogs
        dialogTheme: DialogThemeData(
          backgroundColor: const Color(0xFF1C1A17),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        
        // Custom styling for Text Input Fields (e.g., quantity input)
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF252320),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none, // No border by default
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF6699CC), width: 2), // Blue border when typing
          ),
          labelStyle: const TextStyle(color: Color(0xFFA89F91)),
        ),
        
        // Custom styling for SnackBars (toast notifications at the bottom)
        snackBarTheme: SnackBarThemeData(
          backgroundColor: const Color(0xFF252320),
          contentTextStyle: const TextStyle(color: Color(0xFFD8D4B8)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          behavior: SnackBarBehavior.floating,
        ),
      ),
      
      // Set the initial route/screen of the app
      home: const HomeScreen(),
    );
  }
}

// lib/screens/cooking_mode_screen.dart
import 'package:flutter/material.dart';
import 'dart:async';
import '../models/recipe_model.dart';
import '../config/theme.dart';

class CookingModeScreen extends StatefulWidget {
  const CookingModeScreen({Key? key}) : super(key: key);

  @override
  _CookingModeScreenState createState() => _CookingModeScreenState();
}

class _CookingModeScreenState extends State<CookingModeScreen> {
  late Recipe _recipe;
  int _currentStep = 0;
  bool _isTimerActive = false;
  int _timerSeconds = 0;
  late Timer _timer;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _processArguments();
    });
  }
  
  @override
  void dispose() {
    if (_isTimerActive) {
      _timer.cancel();
    }
    super.dispose();
  }
  
  void _processArguments() {
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null && args is Recipe) {
      setState(() {
        _recipe = args;
      });
    } else {
      // Navigate back if no recipe provided
      Navigator.pop(context);
    }
  }
  
  void _nextStep() {
    if (_currentStep < _recipe.instructions.length - 1) {
      setState(() {
        _currentStep++;
      });
    }
  }
  
  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }
  
  void _startTimer(int minutes) {
    if (_isTimerActive) {
      _timer.cancel();
    }
    
    setState(() {
      _timerSeconds = minutes * 60;
      _isTimerActive = true;
    });
    
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_timerSeconds > 0) {
          _timerSeconds--;
        } else {
          _timer.cancel();
          _isTimerActive = false;
        }
      });
    });
  }
  
  void _stopTimer() {
    if (_isTimerActive) {
      _timer.cancel();
      setState(() {
        _isTimerActive = false;
      });
    }
  }
  
  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }
  
  @override
  Widget build(BuildContext context) {
    // Check if recipe is initialized
    if (!mounted || ModalRoute.of(context)?.settings.arguments == null) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Cooking Mode'),
        actions: [
          IconButton(
            icon: Icon(Icons.timer),
            onPressed: () => _showTimerDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress indicator
          LinearProgressIndicator(
            value: (_currentStep + 1) / _recipe.instructions.length,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(ChefJoTheme.primaryColor),
          ),
          
          // Recipe info
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ChefJoTheme.primaryColor.withOpacity(0.1),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _recipe.title,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Step ${_currentStep + 1} of ${_recipe.instructions.length}',
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isTimerActive)
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: ChefJoTheme.accentColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.timer,
                          color: Colors.white,
                          size: 20,
                        ),
                        SizedBox(width: 4),
                        Text(
                          _formatTime(_timerSeconds),
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          
          // Current instruction
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _recipe.instructions[_currentStep],
                    style: TextStyle(
                      fontSize: 18,
                    ),
                  ),
                  SizedBox(height: 24),
                  
                  // Ingredients for this step (simplified, in reality you'd parse ingredients from steps)
                  Text(
                    'Ingredients Needed:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  ...(_recipe.ingredients.take(3)).map((ingredient) => // Simplified
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            color: ChefJoTheme.primaryColor,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            ingredient.name,
                            style: TextStyle(
                              fontSize: 16,
                            ),
                          ),
                          if (ingredient.quantity != null)
                            Text(
                              ' (${ingredient.quantity})',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Navigation buttons
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: _currentStep > 0 ? _previousStep : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[300],
                    foregroundColor: Colors.black,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.arrow_back),
                      SizedBox(width: 8),
                      Text('Previous'),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: _currentStep < _recipe.instructions.length - 1
                      ? _nextStep
                      : () {
                          // Show completion dialog
                          _showCompletionDialog();
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ChefJoTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: Row(
                    children: [
                      Text(_currentStep < _recipe.instructions.length - 1
                          ? 'Next'
                          : 'Finish'),
                      SizedBox(width: 8),
                      Icon(_currentStep < _recipe.instructions.length - 1
                          ? Icons.arrow_forward
                          : Icons.check),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  void _showTimerDialog() {
    final List<int> presetTimes = [1, 5, 10, 15, 30];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Set Timer'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Choose a preset time or set a custom duration:'),
            SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: presetTimes.map((minutes) {
                return ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _startTimer(minutes);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ChefJoTheme.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: Text('$minutes min'),
                );
              }).toList(),
            ),
            if (_isTimerActive) ...[
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _stopTimer();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: Text('Stop Timer'),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
        ],
      ),
    );
  }
  
  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Recipe Complete!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.restaurant,
              size: 64,
              color: ChefJoTheme.primaryColor,
            ),
            SizedBox(height: 16),
            Text(
              'You have completed cooking ${_recipe.title}',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18),
            ),
            SizedBox(height: 8),
            Text(
              'Enjoy your meal!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Return to previous screen
            },
            child: Text('Exit Cooking Mode'),
          ),
        ],
      ),
    );
  }
}
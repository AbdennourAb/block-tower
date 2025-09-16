import 'package:flutter/material.dart';
import 'dart:math' as math;

// Block data structure
class Block {
  final double x;          // X position (center)
  final double y;          // Y position (bottom)
  final double width;      // Block width
  final double height;     // Block height (always 40)
  final Color color;       // Block color
  final int level;         // Which level this block belongs to

  const Block({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
      required this.color,
    required this.level,
  });

  Block copyWith({
    double? x,
    double? y,
    double? width,
    double? height,
    Color? color,
    int? level,
  }) {
    return Block(
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      color: color ?? this.color,
      level: level ?? this.level,
    );
  }
}

// Game state management
class GameState {
  final List<Block> placedBlocks;
  final Block? movingBlock;
  final int currentLevel;
  final double currentBlockWidth;
  final bool isGameOver;
  final bool isGameStarted;
  final int score;
  final int bestScore;
  final double cameraOffsetY; // Camera vertical offset for tall towers

  const GameState({
    this.placedBlocks = const [],
    this.movingBlock,
    this.currentLevel = 0,
    this.currentBlockWidth = 180.0,
    this.isGameOver = false,
    this.isGameStarted = false,
    this.score = 0,
    this.bestScore = 0,
    this.cameraOffsetY = 0.0,
  });

  GameState copyWith({
    List<Block>? placedBlocks,
    Block? movingBlock,
    int? currentLevel,
    double? currentBlockWidth,
    bool? isGameOver,
    bool? isGameStarted,
    int? score,
    int? bestScore,
    double? cameraOffsetY,
    bool clearMovingBlock = false,
  }) {
    return GameState(
      placedBlocks: placedBlocks ?? this.placedBlocks,
      movingBlock: clearMovingBlock ? null : (movingBlock ?? this.movingBlock),
      currentLevel: currentLevel ?? this.currentLevel,
      currentBlockWidth: currentBlockWidth ?? this.currentBlockWidth,
      isGameOver: isGameOver ?? this.isGameOver,
      isGameStarted: isGameStarted ?? this.isGameStarted,
      score: score ?? this.score,
      bestScore: bestScore ?? this.bestScore,
      cameraOffsetY: cameraOffsetY ?? this.cameraOffsetY,
    );
  }

  // Game constants
  static const double blockHeight = 40.0;
  static const double startingWidth = 180.0;
  static const Color foundationColor = Color(0xFF8B4513); // Earthy brown foundation
  static const double minBlockWidth = 1.0; // Minimum width before game over
  static const int cameraActivationLevel = 12; // Level at which camera starts moving
  
  // Color palette for blocks (10 colors as per brief)
  static const List<Color> blockColors = [
    Colors.red,
    Colors.orange,
    Colors.yellow,
    Colors.green,
    Colors.blue,
    Colors.indigo,
    Colors.pink,
    Colors.teal,
    Colors.cyan,
    Colors.lime,
  ];

  Color getColorForLevel(int level) {
    if (level == 0) return foundationColor; // Purple for foundation
    return blockColors[(level - 1) % blockColors.length];
  }

  // Calculate score for a placed block
  int calculateBlockScore(Block placedBlock, Block? previousBlock) {
    if (previousBlock == null) return 0; // No score for foundation
    
    // Base score for placing a block
    int baseScore = 10;
    
    // Bonus for precision (based on how much width was preserved)
    double widthRatio = placedBlock.width / previousBlock.width;
    int precisionBonus = (widthRatio * 50).round();
    
    // Level multiplier
    int levelMultiplier = currentLevel;
    
    return (baseScore + precisionBonus) * levelMultiplier;
  }
}

// Custom painter for rendering the game
class GamePainter extends CustomPainter {
  final GameState gameState;
  final double pulseScale;

  GamePainter({required this.gameState, this.pulseScale = 1.0});

  @override
  void paint(Canvas canvas, Size size) {
    // Calculate the game area coordinates
    // Y=0 is at the bottom of the screen for game coordinates
    // Canvas Y=0 is at the top, so we need to flip
    
    for (final block in gameState.placedBlocks) {
      _drawBlock(canvas, size, block);
    }
    
    // Draw moving block if it exists (with pulse animation)
    if (gameState.movingBlock != null) {
      _drawBlock(canvas, size, gameState.movingBlock!, isMoving: true);
    }
  }

  void _drawBlock(Canvas canvas, Size size, Block block, {bool isMoving = false}) {
    // Apply pulse scale to moving blocks
    final scale = isMoving ? pulseScale : 1.0;
    final scaledWidth = block.width * scale;
    final scaledHeight = block.height * scale;
    
    // Convert game coordinates to canvas coordinates with camera offset
    final rect = Rect.fromCenter(
      center: Offset(
        block.x,
        size.height - block.y - block.height / 2 + gameState.cameraOffsetY, // Flip Y coordinate and apply camera offset
      ),
      width: scaledWidth,
      height: scaledHeight,
    );

    // Skip drawing if block is completely outside the visible area
    if (rect.bottom < 0 || rect.top > size.height) {
      return;
    }

    // Create solid fill paint and draw an exact rectangle (no rounding, no shadows)
    final paint = Paint()
      ..color = block.color
      ..style = PaintingStyle.fill;

    canvas.drawRect(rect, paint);
    
    // Special styling for foundation block (level 0) to make it unique
    if (block.level == 0) {
      // Add a subtle border pattern to distinguish foundation block
      final borderPaint = Paint()
        ..color = Colors.white.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      
      canvas.drawRect(rect, borderPaint);
    }

    // Level text removed for cleaner look
  }

  @override
  bool shouldRepaint(GamePainter oldDelegate) {
    return gameState != oldDelegate.gameState;
  }
}

void main() {
  runApp(const BlockTowerApp());
}

class BlockTowerApp extends StatelessWidget {
  const BlockTowerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Block Tower Game',
      theme: ThemeData(
        // Dark theme for contrast as specified in the brief
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.purple,
          brightness: Brightness.dark,
        ),
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900], // Dark background
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Game Title
              Text(
                'Block Tower',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              
              // Subtitle
              Text(
                'Block stacking game',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[400],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 60),
              
              // Start Game Button
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const GameScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Start Game',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  GameState gameState = const GameState();
  late AnimationController _animationController;
  late Animation<double> _animation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimation();
    _initializePulseAnimation();
  }

  void _initializePulseAnimation() {
    // Subtle pulse animation for moving block
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _pulseController.repeat(reverse: true);
  }

  void _initializeAnimation() {
    // 4-second cycle as per game brief
    _animationController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );
    
    _animation = Tween<double>(
      begin: 0.0,
      end: 2 * 3.14159, // Full sine wave cycle
    ).animate(_animationController);
    
    _animation.addListener(() {
      if (gameState.movingBlock != null && !gameState.isGameOver) {
        _updateMovingBlockPosition();
      }
    });
    
    _animationController.repeat(); // Continuous loop
  }

  @override
  void dispose() {
    _animationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _initializeGame(double screenWidth) {
    if (gameState.isGameStarted) return; // Already initialized
    
    // Adapt starting width to screen size for better responsiveness
    final adaptedStartingWidth = math.min(GameState.startingWidth, screenWidth * 0.8);
    
    // Create foundation block at center bottom
    // Y coordinate represents the bottom of the block in game coordinates
    final foundationBlock = Block(
      x: screenWidth / 2,
      y: GameState.blockHeight, // Bottom of block is at height = block height
      width: adaptedStartingWidth,
      height: GameState.blockHeight,
      color: GameState.foundationColor,
      level: 0,
    );
    
    setState(() {
      gameState = gameState.copyWith(
        placedBlocks: [foundationBlock],
        isGameStarted: true,
        currentLevel: 1,
        currentBlockWidth: adaptedStartingWidth,
      );
    });
    
    // Start the first moving block
    _createNextMovingBlock();
  }

  void _createNextMovingBlock() {
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Calculate Y position - directly touching the highest placed block
    double nextY = 0;
    for (final block in gameState.placedBlocks) {
      final topY = block.y + block.height;
      if (topY > nextY) nextY = topY;
    }
    
    // Use the current block width (which is the width from previous overlap)
    final nextWidth = gameState.currentBlockWidth;
    
    // Create moving block starting from right side (as per brief)
    // Position it directly on top of the highest block (no gap)
    final movingBlock = Block(
      x: screenWidth, // Start from right edge
      y: nextY, // Directly touching the block below
      width: nextWidth,
      height: GameState.blockHeight,
      color: gameState.getColorForLevel(gameState.currentLevel),
      level: gameState.currentLevel,
    );
    
    setState(() {
      gameState = gameState.copyWith(
        movingBlock: movingBlock,
        currentBlockWidth: nextWidth,
      );
    });
  }

  void _updateMovingBlockPosition() {
    if (gameState.movingBlock == null || gameState.isGameOver) return;
    
    final screenWidth = MediaQuery.of(context).size.width;
    final blockWidth = gameState.movingBlock!.width;
    
    // Calculate movement range: screen width minus current block width
    final movementRange = screenWidth - blockWidth;
    
    // Calculate X position using sine wave
    // Start from right, move to left and back
    final sineValue = math.sin(_animation.value);
    final normalizedSine = (sineValue + 1) / 2; // Convert from [-1,1] to [0,1]
    final x = blockWidth / 2 + (normalizedSine * movementRange);
    
    setState(() {
      gameState = gameState.copyWith(
        movingBlock: gameState.movingBlock!.copyWith(x: x),
      );
    });
  }

  void _onTap() {
    if (gameState.movingBlock == null || gameState.isGameOver) return;
    
    // Calculate overlap with the block below and trim the moving block
    final trimmedBlock = _calculateTrimmedBlock(gameState.movingBlock!);
    
    // Check if the trimmed block is too small (game over condition)
    if (trimmedBlock.width <= GameState.minBlockWidth) {
      final newBestScore = gameState.score > gameState.bestScore ? gameState.score : gameState.bestScore;
      setState(() {
        gameState = gameState.copyWith(
          isGameOver: true,
          bestScore: newBestScore,
        );
      });
      return;
    }
    
    // Advance level and set score equal to current tower level minus 1
    // (no points for first placed block)
    final newLevel = gameState.currentLevel + 1;
    final newScore = math.max(0, newLevel - 1);
    final newBestScore = newScore > gameState.bestScore ? newScore : gameState.bestScore;
    
    // Calculate camera offset for levels 12+ (allow more height before transition)
    double newCameraOffset = gameState.cameraOffsetY;
    
    if (newLevel >= GameState.cameraActivationLevel) {
      // Move camera down by exactly one block height per level after level 11
      // Positive offset pushes rendering downward on screen
      final levelsAboveEleven = newLevel - (GameState.cameraActivationLevel - 1);
      newCameraOffset = levelsAboveEleven * GameState.blockHeight;
    }
    
    setState(() {
      gameState = gameState.copyWith(
        placedBlocks: [...gameState.placedBlocks, trimmedBlock],
        clearMovingBlock: true,
        currentLevel: newLevel,
        currentBlockWidth: trimmedBlock.width,
        score: newScore,
        bestScore: newBestScore,
        cameraOffsetY: newCameraOffset,
      );
    });
    
    // Create next moving block after a brief delay
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted && !gameState.isGameOver) {
        _createNextMovingBlock();
      }
    });
  }

  Block _calculateTrimmedBlock(Block movingBlock) {
    // Find the block directly below the moving block
    Block? blockBelow;
    double maxY = 0;
    
    for (final block in gameState.placedBlocks) {
      final blockTop = block.y + block.height;
      if (blockTop > maxY && blockTop <= movingBlock.y) {
        maxY = blockTop;
        blockBelow = block;
      }
    }
    
    if (blockBelow == null) {
      // No block below (shouldn't happen), return original block
      return movingBlock;
    }
    
    // Calculate overlap
    final movingLeft = movingBlock.x - movingBlock.width / 2;
    final movingRight = movingBlock.x + movingBlock.width / 2;
    final belowLeft = blockBelow.x - blockBelow.width / 2;
    final belowRight = blockBelow.x + blockBelow.width / 2;
    
    // Calculate overlapping area
    final overlapLeft = math.max(movingLeft, belowLeft);
    final overlapRight = math.min(movingRight, belowRight);
    final overlapWidth = math.max(0.0, overlapRight - overlapLeft);
    
    if (overlapWidth <= 0) {
      // No overlap - game over
      return movingBlock.copyWith(width: 0);
    }
    
    // Ensure minimum overlap precision (avoid floating point issues)
    final finalOverlapWidth = overlapWidth < 0.1 ? 0.0 : overlapWidth;
    if (finalOverlapWidth <= 0) {
      return movingBlock.copyWith(width: 0);
    }
    
    // Create trimmed block with only the overlapping portion
    final newCenterX = (overlapLeft + overlapRight) / 2;
    
    // Clamp the new center to screen bounds
    final screenWidth = MediaQuery.of(context).size.width;
    final clampedCenterX = math.max(
      finalOverlapWidth / 2,
      math.min(screenWidth - finalOverlapWidth / 2, newCenterX),
    );
    
    return movingBlock.copyWith(
      x: clampedCenterX,
      width: finalOverlapWidth,
    );
  }

  void _restartGame() {
    // Preserve the best score
    final bestScore = gameState.bestScore;
    
    setState(() {
      gameState = GameState(bestScore: bestScore);
    });
    
    // Reinitialize the game
    _initializeGame(MediaQuery.of(context).size.width);
  }

  @override
  Widget build(BuildContext context) {
    // Initialize game on first build
    _initializeGame(MediaQuery.of(context).size.width);
    
    return Scaffold(
      backgroundColor: Colors.grey[900],
      body: SafeArea(
        child: Column(
          children: [
            // UI Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Top row: Back button, Level, Size bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Back button
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                      ),
                      
                      // Score display
                      Text(
                        'Score: ${gameState.score}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      
                      // Best score with styling
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.orange.withOpacity(0.3), width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.emoji_events,
                              color: Colors.orange,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Best: ${gameState.bestScore}',
                              style: TextStyle(
                                color: Colors.orange,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                ],
              ),
            ),
            
            // Game Area
            Expanded(
              child: Container(
                width: double.infinity,
                color: Colors.grey[900],
                child: Stack(
                  children: [
                    // Game Canvas
                    Positioned.fill(
                      child: GestureDetector(
                        onTap: _onTap,
                        child: AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, child) {
                            return CustomPaint(
                              painter: GamePainter(
                                gameState: gameState,
                                pulseScale: _pulseAnimation.value,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    
                    // Game Over Overlay
                    if (gameState.isGameOver)
                      Positioned.fill(
                        child: Container(
                          color: Colors.black.withOpacity(0.8),
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.all(32),
                              margin: const EdgeInsets.symmetric(horizontal: 32),
                              decoration: BoxDecoration(
                                color: Colors.grey[900],
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.white.withOpacity(0.2)),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (gameState.score == gameState.bestScore && gameState.score > 0)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.amber.withOpacity(0.8),
                                            Colors.orange.withOpacity(0.6),
                                            Colors.amber.withOpacity(0.8),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: Colors.amber, width: 2),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.amber.withOpacity(0.3),
                                            blurRadius: 20,
                                            spreadRadius: 5,
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        children: [
                                          Text(
                                            '👑',
                                            style: TextStyle(fontSize: 32),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'BEST SCORE',
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 2,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                          Text(
                                            '${gameState.score}',
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 36,
                                              fontWeight: FontWeight.w900,
                                              shadows: [
                                                Shadow(
                                                  color: Colors.white.withOpacity(0.5),
                                                  offset: Offset(1, 1),
                                                  blurRadius: 2,
                                                ),
                                              ],
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    )
                                  else ...[
                                    Text(
                                      'GAME OVER',
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      'Score: ${gameState.score}',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                  
                                  const SizedBox(height: 24),
                                  
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: _restartGame,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.purple,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(vertical: 16),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                          child: const Text(
                                            'PLAY AGAIN',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: ElevatedButton(
                                          onPressed: () => Navigator.pop(context),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.grey[700],
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(vertical: 16),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                          child: const Text(
                                            'MENU',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    
                    // Debug overlay removed
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
  static const Color foundationColor = Colors.purple;
  static const double minBlockWidth = 1.0; // Minimum width before game over
  static const int cameraActivationLevel = 9; // Level at which camera starts moving
  
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

    // Create paint for the block
    final paint = Paint()
      ..color = block.color
      ..style = PaintingStyle.fill;

    // Draw enhanced shadow with gradient effect (optimized for performance)
    final shadowOffset = 3.0;
    final shadowBlur = 6.0;
    
    // Reduce shadow layers for very small blocks to improve performance
    final shadowLayers = block.width < 30 ? 1 : (block.width < 60 ? 2 : 3);
    
    // Multiple shadow layers for depth
    for (int i = 0; i < shadowLayers; i++) {
      final offset = shadowOffset * (i + 1) / shadowLayers;
      final opacity = 0.2 - (i * 0.05);
      final shadowRect = rect.translate(offset, offset);
      final shadowPaint = Paint()
        ..color = Colors.black.withOpacity(opacity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, shadowBlur - i);
      
      canvas.drawRRect(
        RRect.fromRectAndRadius(shadowRect, const Radius.circular(6)),
        shadowPaint,
      );
    }

    // Create gradient paint for the main block
    final gradientPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          block.color.withOpacity(0.9),
          block.color,
          block.color.withOpacity(0.8),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(rect);

    // Draw the main block with gradient
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(6)),
      gradientPaint,
    );

    // Draw highlight on top edge
    final highlightRect = Rect.fromLTWH(rect.left, rect.top, rect.width, rect.height * 0.3);
    final highlightPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withOpacity(0.3),
          Colors.white.withOpacity(0.0),
        ],
      ).createShader(highlightRect);

    canvas.drawRRect(
      RRect.fromRectAndRadius(highlightRect, const Radius.circular(6)),
      highlightPaint,
    );

    // Draw subtle outline
    final outlinePaint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(6)),
      outlinePaint,
    );

    // Draw level text on block with better styling
    if (block.width > 50) { // Only show text if block is wide enough
      final fontSize = math.min(14.0, block.width / 10);
      
      // Draw text shadow first
      final shadowTextPainter = TextPainter(
        text: TextSpan(
          text: 'L${block.level}',
          style: TextStyle(
            color: Colors.black.withOpacity(0.5),
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      
      shadowTextPainter.layout();
      shadowTextPainter.paint(
        canvas,
        Offset(
          rect.center.dx - shadowTextPainter.width / 2 + 1,
          rect.center.dy - shadowTextPainter.height / 2 + 1,
        ),
      );
      
      // Draw main text
      final textPainter = TextPainter(
        text: TextSpan(
          text: 'L${block.level}',
          style: TextStyle(
            color: Colors.white,
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            shadows: [
              Shadow(
                color: Colors.black.withOpacity(0.3),
                offset: const Offset(1, 1),
                blurRadius: 2,
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          rect.center.dx - textPainter.width / 2,
          rect.center.dy - textPainter.height / 2,
        ),
      );
    }
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
              const SizedBox(height: 20),
              
              // Subtitle
              Text(
                'Physics-based block stacking game',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[400],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              
              // Foundation block preview (purple base block)
              Container(
                width: 180, // Starting width as per brief
                height: 40,  // Block height as per brief
                decoration: BoxDecoration(
                  color: Colors.purple,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'Foundation Block', 
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              
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
              const SizedBox(height: 20),
              
              // Instructions
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  'Tap to drop blocks.\nOnly overlapping portion survives.\nPrecision determines your score!',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
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
      if (gameState.movingBlock != null) {
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
    if (gameState.movingBlock == null) return;
    
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
    
    // Calculate score for this placement
    final previousBlock = gameState.placedBlocks.isNotEmpty ? gameState.placedBlocks.last : null;
    final blockScore = gameState.calculateBlockScore(trimmedBlock, previousBlock);
    final newScore = gameState.score + blockScore;
    final newBestScore = newScore > gameState.bestScore ? newScore : gameState.bestScore;
    
    // Calculate camera offset for levels 9+ (as per game brief)
    final newLevel = gameState.currentLevel + 1;
    double newCameraOffset = gameState.cameraOffsetY;
    
    if (newLevel >= GameState.cameraActivationLevel) {
      // Move camera down by exactly one block height per level after level 8
      // This keeps the current action centered as per the brief
      final levelsAboveEight = newLevel - (GameState.cameraActivationLevel - 1);
      newCameraOffset = -levelsAboveEight * GameState.blockHeight;
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
                      
                      // Level counter
                      Text(
                        'Level ${gameState.currentLevel}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      
                  // Size percentage bar (responsive width)
                  Container(
                    width: math.min(100, MediaQuery.of(context).size.width * 0.25),
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.grey[700],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: math.max(0.05, gameState.currentBlockWidth / math.max(GameState.startingWidth, MediaQuery.of(context).size.width * 0.8)),
                      child: Container(
                        decoration: BoxDecoration(
                          color: gameState.currentBlockWidth < 50 ? Colors.red : 
                                (gameState.currentBlockWidth < 100 ? Colors.orange : Colors.green),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Bottom row: Score and Best Score
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Score: ${gameState.score}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 20),
                      Text(
                        'Best: ${gameState.bestScore}',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
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
                                    'Level ${gameState.currentLevel}',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  
                                  Text(
                                    'Final Score: ${gameState.score}',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  
                                  if (gameState.score == gameState.bestScore && gameState.score > 0)
                                    Text(
                                      '🏆 NEW BEST SCORE! 🏆',
                                      style: TextStyle(
                                        color: Colors.orange,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  
                                  if (gameState.bestScore > 0 && gameState.score != gameState.bestScore)
                                    Text(
                                      'Best Score: ${gameState.bestScore}',
                                      style: TextStyle(
                                        color: Colors.orange,
                                        fontSize: 16,
                                      ),
                                    ),
                                  
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
                    
                    // Debug overlay
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              gameState.isGameOver ? 'GAME OVER' : '✅ GAME COMPLETE!',
                              style: TextStyle(
                                color: gameState.isGameOver ? Colors.red : Colors.green,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Blocks: ${gameState.placedBlocks.length}',
                              style: TextStyle(color: Colors.white, fontSize: 10),
                            ),
                            Text(
                              'Moving: ${gameState.movingBlock != null ? "Yes" : "No"}',
                              style: TextStyle(color: Colors.white, fontSize: 10),
                            ),
                            Text(
                              'Level: ${gameState.currentLevel}',
                              style: TextStyle(color: Colors.white, fontSize: 10),
                            ),
                            Text(
                              'Width: ${gameState.currentBlockWidth.toStringAsFixed(1)}',
                              style: TextStyle(color: Colors.white, fontSize: 10),
                            ),
                            Text(
                              'Score: ${gameState.score}',
                              style: TextStyle(color: Colors.white, fontSize: 10),
                            ),
                            Text(
                              'Camera: ${gameState.cameraOffsetY.toStringAsFixed(1)}',
                              style: TextStyle(color: Colors.white, fontSize: 10),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              gameState.isGameOver ? 'GAME OVER' : 'TAP TO PLACE BLOCK',
                              style: TextStyle(
                                color: gameState.isGameOver 
                                  ? Colors.red 
                                  : (gameState.movingBlock != null ? Colors.yellow : Colors.grey),
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
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
          ],
        ),
      ),
    );
  }
}

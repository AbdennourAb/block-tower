# Block Tower Game - Game Design Brief

## Core Concept
Physics-based block stacking game where precision placement determines survival. Each block gets smaller based on placement accuracy.

## Gameplay Loop
1. **Foundation**: Purple base block auto-placed at center (Level 0)
2. **Movement**: Blocks oscillate left-right using smooth sine wave motion
3. **Placement**: Tap to drop block - only overlapping portion survives
4. **Progression**: Next block size = overlapping area from previous placement
5. **Challenge**: Blocks get progressively smaller, requiring more precision

## Game Rules
- **Start**: Blocks begin moving from right side (prevents quick-tap exploit)
- **Physics**: Perfect overlap calculation - outside parts "fall away"
- **End Game**: No overlap OR block becomes too thin (≤1 unit)
- **No Strikes**: Game continues until physical impossibility

## Visual Design
- **Style**: Clean, geometric blocks with modern shadows
- **Colors**: Vibrant rotating palette (10 colors), special purple for foundation
- **UI**: Minimal during gameplay - level counter and size percentage bar
- **Background**: Dark theme for contrast

## Camera Behavior
- **Early Levels (1-8)**: Static view
- **High Levels (9+)**: Camera follows action by moving tower down
- **Movement**: Exactly one block-height per level to keep current action centered

## Technical Requirements
- **Platform**: Mobile (portrait orientation)
- **Interaction**: Single tap to place blocks
- **Animation**: Smooth 60fps sine wave movement (4-second cycle)
- **Physics**: Geometric overlap detection with pixel-perfect trimming
- **Responsive**: Adapts to different screen sizes

## Key Measurements
- **Block Height**: 40 units (consistent)
- **Starting Width**: 180 units
- **Movement Range**: Screen width minus current block width
- **Camera Trigger**: Level 9
- **Minimum Width**: 1 unit before game over

## Unique Features
- **Progressive Difficulty**: Self-adjusting based on player skill
- **No Artificial Limits**: Game can theoretically continue indefinitely
- **Visual Trimming**: Players see exactly what survives each placement
- **Smooth Camera**: Intelligent view management for tall towers

This creates an addictive, skill-based game where each playthrough feels unique based on placement accuracy.

import 'package:flutter/material.dart';

enum TileType {
  walkable,
  nonWalkable,
  path,
  beacon1,
  beacon2,
  beacon3,
}

class GridMap extends StatefulWidget {
  const GridMap({super.key});

  @override
  _GridMapState createState() => _GridMapState();
}

class _GridMapState extends State<GridMap> {
  List<List<TileType>> tiles = [];

  @override
  void initState() {
    super.initState();
    initializeGrid();
  }

  void initializeGrid() {
    // Initialize the grid with walkable and non-walkable tiles
    tiles = List.generate(
      64, // Change the total number of rows to 64
      (rowIndex) => List.generate(
        34,
        (colIndex) {
          // Adjust according to the specified configuration
          if (rowIndex == 0 && colIndex == 33) {
            return TileType.beacon1; // Set Beacon1
          } else if (rowIndex == 31 && colIndex == 0) {
            return TileType.beacon2; // Set Beacon2
          } else if (rowIndex == 63 && colIndex == 33) {
            return TileType.beacon3; // Set Beacon3
          } else if (rowIndex >= 0 && rowIndex <= 8) {
            // 1st row to 9th row, tiles 31-34 are non-walkable
            if (colIndex >= 30) {
              return TileType.nonWalkable;
            } else {
              return TileType.walkable;
            }
          } else if (rowIndex >= 9 && rowIndex <= 34) {
            // 10th row to 34th row
            if (colIndex >= 0 && colIndex <= 4 ||
                colIndex >= 10 && colIndex <= 14 ||
                colIndex >= 20 && colIndex <= 24 ||
                colIndex >= 30) {
              return TileType.nonWalkable;
            } else if (rowIndex == 34) {
              // 35th row
              if (colIndex >= 0 && colIndex <= 4 ||
                  colIndex >= 10 && colIndex <= 14 ||
                  colIndex >= 20 && colIndex <= 24) {
                return TileType.nonWalkable;
              }
            }
          } else if (rowIndex == 35) {
            // 35th row
            if (colIndex >= 0 && colIndex <= 4 ||
                colIndex >= 10 && colIndex <= 14 ||
                colIndex >= 20 && colIndex <= 24) {
              return TileType.nonWalkable;
            } else {
              return TileType.walkable;
            }
          } else if (rowIndex >= 36 && rowIndex <= 41) {
            // 36th row to 41st row, all walkable
            return TileType.walkable;
          } else if (rowIndex >= 42 && rowIndex <= 53) {
            // 42nd row to 53rd row
            if (colIndex >= 5 && colIndex <= 9) {
              return TileType.walkable;
            } else {
              return TileType.nonWalkable;
            }
          } else if (rowIndex >= 60 && rowIndex <= 63) {
            // 54th row to 59th row, all walkable
            return TileType.nonWalkable;
          }
          return TileType.walkable;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double tileSize = screenSize.width / 34;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Grid Map Example'),
      ),
      body: GridView.builder(
        itemCount: tiles.length * tiles[0].length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: tiles[0].length,
          childAspectRatio: 1.0,
        ),
        itemBuilder: (context, index) {
          int rowIndex = index ~/ tiles[0].length;
          int colIndex = index % tiles[0].length;
          return _buildTileWidget(
              tiles[rowIndex][colIndex], tileSize, rowIndex, colIndex);
        },
      ),
    );
  }

  Widget _buildTileWidget(
      TileType type, double tileSize, int rowIndex, int colIndex) {
    Color color;
    switch (type) {
      case TileType.walkable:
        color = Colors.green;
        break;
      case TileType.nonWalkable:
        color = Colors.red;
        break;
      case TileType.path:
        color = Colors.blue;
        break;
      case TileType.beacon1:
        color = Colors.orange; // Beacon1 color
        break;
      case TileType.beacon2:
        color = Colors.yellow; // Beacon2 color
        break;
      case TileType.beacon3:
        color = Colors.purple; // Beacon3 color
        break;
    }
    return Container(
      width: tileSize,
      height: tileSize,
      margin: const EdgeInsets.all(1),
      color: color,
    );
  }
}

void main() {
  runApp(const MaterialApp(
    home: GridMap(),
  ));
}

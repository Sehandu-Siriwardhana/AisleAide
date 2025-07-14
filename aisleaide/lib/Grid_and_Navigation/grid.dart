import 'dart:async';
import 'dart:math';
import 'package:aisleaide/Firebase_and_beacons/beacon.dart';
import 'package:aisleaide/Voice_assistant_and_database/camera_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_tts/flutter_tts.dart';

// Creating the grid map
//tile types
enum TileType {
  walkable,
  nonWalkable,
  path,
  beacon1,
  beacon2,
  beacon3,
  aisle1RightShelf1,
  aisle1RightShelf2,
  aisle1RightShelf3,
}

GlobalKey<_GridMapState> gridMapKey = GlobalKey<_GridMapState>();

//defining a class for the GridMap
class GridMap extends StatefulWidget {
  final String productName;

  const GridMap({super.key, required this.productName});

  @override
  _GridMapState createState() => _GridMapState();
}

class _GridMapState extends State<GridMap> {
  List<List<String>> tiles = [];
  final FlutterTts flutterTts = FlutterTts(); // Initialize FlutterTts
  double txPower = -65; // TX power of the beacons
  int userRowIndex = 56; // User's current row index on the grid
  int userColIndex = 33; // User's current column index on the grid
  double closestBeaconDistance = double.infinity; // Closest beacon distance
  late List<List<Node>> grid;

  Stream<Map<String, bool>> startBeaconTrackingStream() {
    return BeaconService().startBeaconTrackingStream();
  }

  @override
  void initState() {
    super.initState();
    initializeGrid();
    grid = createGrid();

    getProductLocation(widget.productName).then((location) {
      if (location != null) {
        print('Location of ${widget.productName}: $location');
        // Call findPath with the obtained location
        findPath(userRowIndex, userColIndex, location);
      } else {
        print('Product ${widget.productName} not found in the database.');
      }
    });
  }

  @override
  void dispose() {
    BeaconService().stopBeaconTracking();
    super.dispose();
  }

  //defining te rows and columns of the grid by assiginign speicific tile types
  void initializeGrid() {
    // Initialize the grid with walkable and non-walkable tiles
    tiles = List.generate(
      64, // Change the total number of rows to 64
      (rowIndex) => List.generate(
        34,
        (colIndex) {
          // Adjust according to the specified configuration
          if (rowIndex == 0 && colIndex == 33) {
            return 'beacon1'; // Set Beacon1
          } else if (rowIndex == 31 && colIndex == 0) {
            return 'beacon2'; // Set Beacon2
          } else if (rowIndex == 63 && colIndex == 33) {
            return 'beacon3'; // Set Beacon3
          } else if (rowIndex >= 0 && rowIndex <= 8) {
            // 1st row to 9th row, tiles 31-33 are non-walkable
            if (colIndex >= 30) {
              return 'nonWalkable';
            } else {
              return 'walkable';
            }
          } else if (rowIndex >= 9 && rowIndex <= 34) {
            // 10th row to 34th row
            if (colIndex >= 0 && colIndex <= 4 ||
                colIndex >= 10 && colIndex <= 14 ||
                colIndex >= 20 && colIndex <= 24 ||
                colIndex >= 30) {
              return 'nonWalkable';
            } else if (rowIndex == 34) {
              // 35th row
              if (colIndex >= 0 && colIndex <= 4 ||
                  colIndex >= 10 && colIndex <= 14 ||
                  colIndex >= 20 && colIndex <= 24) {
                return 'nonWalkable';
              }
            }
          } else if (rowIndex == 35) {
            // 35th row
            if (colIndex >= 0 && colIndex <= 4 ||
                colIndex >= 10 && colIndex <= 14 ||
                colIndex >= 20 && colIndex <= 24) {
              return 'nonWalkable';
            } else {
              return 'walkable';
            }
          } else if (rowIndex >= 36 && rowIndex <= 41) {
            // 36th row to 41st row, all walkable
            return 'walkable';
          } else if (rowIndex >= 42 && rowIndex <= 53) {
            // 42nd row to 53rd row
            if (colIndex >= 5 && colIndex <= 9) {
              return 'walkable';
            } else {
              return 'nonWalkable';
            }
          } else if (rowIndex >= 60 && rowIndex <= 63) {
            // 54th row to 59th row, all walkable
            return 'nonWalkable';
          }
          return 'walkable';
        },
      ),
    );

    // Assigning the newly added cell types
    tiles[27][29] = 'Aisle1RightShelf1';
    tiles[16][29] = 'Aisle1RightShelf2';
    tiles[4][29] = 'Aisle1RightShelf3';
    tiles[31][19] = 'Aisle2RightShelf1';
    tiles[25][19] = 'Aisle2RightShelf2';
    tiles[18][19] = 'Aisle2RightShelf3';
    tiles[12][19] = 'Aisle2RightShelf4';
    tiles[31][15] = 'Aisle2LefttShelf1';
    tiles[25][15] = 'Aisle2LefttShelf2';
    tiles[18][15] = 'Aisle2LefttShelf3';
    tiles[12][15] = 'Aisle2LefttShelf4';
    tiles[31][9] = 'Aisle3RightShelf1';
    tiles[25][9] = 'Aisle3RightShelf2';
    tiles[18][9] = 'Aisle3RightShelf3';
    tiles[12][9] = 'Aisle3RightShelf4';
    tiles[31][5] = 'Aisle3LeftShelf1';
    tiles[25][5] = 'Aisle3LeftShelf2';
    tiles[18][5] = 'Aisle3LeftShelf3';
    tiles[12][5] = 'Aisle3LeftShelf4';
  }

//beacon
  void startBeaconTracking() async {}

  double calculateDistance(double rssi) {
    double txPower = -65; // TX power of the beacons
    double pathLossExponent = 2; // Path loss exponent
    return pow(10, ((txPower - rssi) / (10 * pathLossExponent))).toDouble();
  }

  void updateUserLocationFromBeacon(Map<String, bool> beaconStatus) {
    double closestBeaconDistance = double.infinity;
    int closestBeaconX = -1;
    int closestBeaconY = -1;

    // Iterate through each beacon and calculate distance
    beaconStatus.forEach((key, value) {
      if (value) {
        double distance =
            calculateDistance(-56.0); // Use the provided RSSI value
        if (distance < closestBeaconDistance) {
          closestBeaconDistance = distance;
          // Update coordinates based on closest beacon
          switch (key) {
            case 'beacon1':
              closestBeaconX = 0;
              closestBeaconY = 33;
              break;
            case 'beacon2':
              closestBeaconX = 31;
              closestBeaconY = 0;
              break;
            case 'beacon3':
              closestBeaconX = 63;
              closestBeaconY = 33;
              break;
            default:
              break;
          }
        }
      }
    });

    // Update user's position only if a closer beacon is found
    if (closestBeaconDistance != double.infinity) {
      setState(() {
        userRowIndex = closestBeaconX;
        userColIndex = closestBeaconY;
      });
    } else {
      // Handle no beacon detection (optional)
      print('No beacons detected. User location unknown.');
      // Set userRowIndex and userColIndex to a default value (e.g., -1)
    }
  }

//build method for the GridMApState class
  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final double tileSize = screenSize.width / 34;

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to the camera screen
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CameraScreen()),
          );
        },
        child: const Icon(Icons.camera_alt_outlined),
      ),
      body: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: const Color.fromARGB(255, 0, 0, 0),
            width: 5.0,
          ),
        ),
        child: GridView.builder(
          key: gridMapKey,
          itemCount: tiles.length * tiles[0].length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: tiles[0].length,
            childAspectRatio: 1.0,
          ),
          itemBuilder: (context, index) {
            int rowIndex = index ~/ tiles[0].length;
            int colIndex = index % tiles[0].length;
            return _buildTileWidget(
              tiles[rowIndex][colIndex],
              tileSize,
              rowIndex,
              colIndex,
            );
          },
        ),
      ),
    );
  }

//building a single tile widget based on the type of tile
  Widget _buildTileWidget(
      String type, double tileSize, int rowIndex, int colIndex) {
    Color color;
    switch (type) {
      case 'walkable':
        color = const Color.fromARGB(255, 54, 244, 149);
        break;
      case 'nonWalkable':
        color = const Color.fromARGB(255, 199, 192, 192);
        break;
      case 'path':
        color = const Color.fromARGB(255, 6, 59, 102);
        break;
      case 'beacon1':
        color = Colors.orange; // Beacon1 color
        break;
      case 'beacon2':
        color = Colors.yellow; // Beacon2 color
        break;
      case 'beacon3':
        color = Colors.purple; // Beacon3 color
        break;
      case 'Aisle1RightShelf1':
      case 'Aisle1RightShelf2':
      case 'Aisle1RightShelf3':
      case 'Aisle2RightShelf1':
      case 'Aisle2RightShelf2':
      case 'Aisle2RightShelf3':
      case 'Aisle2RightShelf4':
      case 'Aisle2LefttShelf1':
      case 'Aisle2LefttShelf2':
      case 'Aisle2LefttShelf3':
      case 'Aisle2LefttShelf4':
      case 'Aisle3RightShelf1':
      case 'Aisle3RightShelf2':
      case 'Aisle3RightShelf3':
      case 'Aisle3RightShelf4':
      case 'Aisle3LeftShelf1':
      case 'Aisle3LeftShelf2':
      case 'Aisle3LeftShelf3':
      case 'Aisle3LeftShelf4':
        color = const Color.fromARGB(255, 5, 12, 112); // Newly added cell types
        break;
      default:
        color = Colors.transparent;
        break;
    }

    // Add a condition to display the user's position on the grid
    if (rowIndex == userRowIndex && colIndex == userColIndex) {
      color = Colors.blueAccent; // Change color for user's position
    }

    return GestureDetector(
      onTap: () {
        // Handle tile tap event
        print('Tile tapped: ($rowIndex, $colIndex)');
      },
      child: Container(
        width: tileSize,
        height: tileSize,
        margin: const EdgeInsets.all(1),
        color: color,
        child: Center(
          child: Text(
            '($rowIndex, $colIndex)',
            style: const TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }

  //---creating nodes---//
  List<List<Node>> createGrid() {
    return List.generate(tiles.length, (row) {
      return List.generate(tiles[0].length, (col) {
        return Node(row, col, tiles[row][col] == 'walkable');
      });
    });
  }

  Future<String?> getProductLocation(String productName) async {
    try {
      print('Searching for product: $productName');
      // Reference to your Firestore collection
      CollectionReference productsCollection =
          FirebaseFirestore.instance.collection('Products');

      // Query to get the product document with the specified name
      QuerySnapshot querySnapshot = await productsCollection
          .where('Product Name',
              isEqualTo: productName.toLowerCase()) // Update field name
          .get();

      print('Query executed');

      // Check if any documents match the query
      if (querySnapshot.docs.isNotEmpty) {
        // Get the first document (assuming there's only one product with that name)
        Map<String, dynamic> data =
            querySnapshot.docs.first.data() as Map<String, dynamic>;

        // Retrieve the "Shelf" field from the document
        String? shelfLocation = data['Shelf'];

        // Return the shelf location
        print('Product location found: $shelfLocation');
        return shelfLocation;
      } else {
        // Product not found
        print('Product not found in the database.');
        return null;
      }
    } catch (error) {
      // Handle errors
      print('Error retrieving product location: $error');
      return null;
    }
  }
  //---finding the path from starting node to the end node---//

  //method take four parameters representing the four cordinated of hte start and end points
  void findPath(int startX, int startY, String endLocation) {
    // Convert location string to row and column indices
    int endX;
    int endY;

    switch (endLocation) {
      case 'Aisle1RightShelf1':
        endX = 27;
        endY = 29;
        break;
      case 'Aisle1RightShelf2':
        endX = 16;
        endY = 29;
        break;
      case 'Aisle1RightShelf3':
        endX = 4;
        endY = 29;
        break;
      case 'Aisle2RightShelf1':
        endX = 31;
        endY = 19;
        break;
      case 'Aisle2RightShelf2':
        endX = 25;
        endY = 19;
        break;
      case 'Aisle2RightShelf3':
        endX = 18;
        endY = 19;
        break;
      case 'Aisle2RightShelf4':
        endX = 12;
        endY = 19;
        break;
      case 'Aisle2LeftShelf1':
        endX = 31;
        endY = 15;
        break;
      case 'Aisle2LeftShelf2':
        endX = 25;
        endY = 15;
        break;
      case 'Aisle2LeftShelf3':
        endX = 28;
        endY = 15;
        break;
      case 'Aisle2LeftShelf4':
        endX = 12;
        endY = 15;
        break;
      case 'Aisle3RightShelf1':
        endX = 31;
        endY = 9;
        break;
      case 'Aisle3RightShelf2':
        endX = 25;
        endY = 9;
        break;
      case 'Aisle3RightShelf3':
        endX = 18;
        endY = 9;
        break;
      case 'Aisle3RightShelf4':
        endX = 12;
        endY = 9;
        break;
      case 'Aisle3LeftShelf1':
        endX = 31;
        endY = 5;
        break;
      case 'Aisle3LeftShelf2':
        endX = 25;
        endY = 5;
        break;
      case 'Aisle3LeftShelf3':
        endX = 18;
        endY = 5;
        break;
      case 'Aisle3LeftShelf4':
        endX = 12;
        endY = 5;
        break;
      default:
        print('Invalid location: $endLocation');
        return;
    }

    startX = userRowIndex;
    startY = userColIndex;

    Node startNode = grid[startX][startY];
    Node endNode = grid[endX][endY];

    List<Node> openList = [];
    List<Node> closedList = [];

    openList.add(startNode);

    //pathfinding loop
    while (openList.isNotEmpty) {
      Node currentNode = openList[0];
      for (int i = 1; i < openList.length; i++) {
        //selects a node wit the lowest fCost
        if (openList[i].fCost < currentNode.fCost ||
            (openList[i].fCost == currentNode.fCost &&
                openList[i].hCost < currentNode.hCost)) {
          currentNode = openList[i];
        }
      }

      openList.remove(currentNode);
      closedList.add(currentNode);

      //goal check - if the current node is equal to the end node, that means the goal has been reached
      if (currentNode == endNode) {
        // Path found
        List<Node> path = [];
        Node current = currentNode;
        while (current != startNode) {
          path.add(current);
          current = current.parent!;
        }
        path.add(startNode);
        // Reverse the path
        path = List.from(path.reversed);

        // Mark the path on the grid
        for (Node node in path) {
          tiles[node.row][node.col] = 'path';
        }
        //updating the newly marked path in the UI
        setState(() {});
        //calling the instructions
        generateNavigationInstructions(path);
        return;
      }

      bool isShelfTile(Node node) {
        String tileType = tiles[node.row][node.col];
        return tileType.startsWith('Aisle');
      }

      for (Node neighbor in getNeighbors(currentNode)) {
        if (!(neighbor.walkable || isShelfTile(neighbor)) ||
            closedList.contains(neighbor)) {
          continue;
        }

        int newCostToNeighbor =
            currentNode.gCost + getDistance(currentNode, neighbor);
        if (newCostToNeighbor < neighbor.gCost ||
            !openList.contains(neighbor)) {
          neighbor.gCost = newCostToNeighbor;
          neighbor.hCost = getDistance(neighbor, endNode);
          neighbor.parent = currentNode;

          if (!openList.contains(neighbor)) {
            openList.add(neighbor);
          }
        }
      }
    }
  }

  List<Node> getNeighbors(Node node) {
    List<Node> neighbors = [];
    if (node.row > 0) neighbors.add(grid[node.row - 1][node.col]); // Top
    if (node.row < grid.length - 1) {
      neighbors.add(grid[node.row + 1][node.col]); // Bottom
    }
    if (node.col > 0) neighbors.add(grid[node.row][node.col - 1]); // Left
    if (node.col < grid[0].length - 1) {
      neighbors.add(grid[node.row][node.col + 1]); // Right
    }
    return neighbors;
  }

  int getDistance(Node nodeA, Node nodeB) {
    int dstX = (nodeA.row - nodeB.row).abs();
    int dstY = (nodeA.col - nodeB.col).abs();
    return dstX + dstY;
  }

  //generating instructions

  Future<void> generateNavigationInstructions(List<Node> path) async {
  List<String> instructions = [];

  // Initialize variables
  int steps = 0; // Distance in steps
  String direction =
      ''; // Current direction (e.g., 'forward', 'backward', 'left', 'right')

  // Iterate through the path
  for (int i = 1; i < path.length; i++) {
    Node current = path[i];
    Node previous = path[i - 1];

    // Determine direction
    String currentDirection = '';
    if (current.row < previous.row) {
      currentDirection = 'forward';
    } else if (current.row > previous.row) {
      currentDirection = 'backward';
    } else if (current.col < previous.col) {
      currentDirection = 'left';
    } else if (current.col > previous.col) {
      currentDirection = 'right';
    }

    // Check for direction change
    if (currentDirection != direction) {
      // Append instructions for the previous direction
      if (steps > 0) {
        instructions.add('Move $steps steps $direction');
      }

      // Update direction and reset steps
      direction = currentDirection;
      steps = 2; // Reset steps to the number of steps per meter
    } else {
      // Increment steps
      steps += 2; // Increment steps by the number of steps per meter
    }
  }

  // Print navigation instructions
  for (int i = 0; i < instructions.length; i++) {
    // Speak the instruction
    print('Navigation Instruction: ${instructions[i]}');
    await flutterTts.setSpeechRate(0.3);
    await flutterTts.speak(instructions[i]);

    // Add a delay of 5 seconds if it's not the last instruction
    if (i != instructions.length - 1) {
      await Future.delayed(Duration(seconds: 5));
    }
  }
  }
}


class Node {
  int row;
  int col;
  bool walkable;
  late int gCost;
  late int hCost;
  Node? parent;

  Node(this.row, this.col, this.walkable) {
    gCost = 0; // Initialize gCost
    hCost = 0; // Initialize hCost
    parent = null;
  }

  int get fCost => gCost + hCost;
}

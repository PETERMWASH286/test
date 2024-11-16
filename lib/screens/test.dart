class HomePage extends StatelessWidget {
  const HomePage({super.key});



Future<Map<String, dynamic>> fetchMaintenanceData() async {
  try {
    final maintenanceData = await fetchMaintenanceCosts();
    final userCars = await fetchUserCars();
    final recentServices = await fetchRecentServices();
    return {
      "maintenanceData": maintenanceData ?? {},
      "userCars": userCars ?? [],
      "recentServices": recentServices ?? []
    };
  } catch (e) {
    print("Error fetching data: $e");
    return {
      "maintenanceData": {},
      "userCars": [],
      "recentServices": []
    };
  }
}


Future<List<dynamic>> fetchUserCars() async {
  try {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('jwt_token');

    if (token == null) {
      throw Exception('Token is missing!');
    }

    final response = await http.get(
      Uri.parse('https://expertstrials.xyz/Garifix_app/api/user_cars'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      // Debugging: Print the raw response body
      print('Response body: ${response.body}');
      
      // Decode the response and access the 'cars' key
      final Map<String, dynamic> responseData = json.decode(response.body);

      // Debugging: Print the decoded response data
      print('Decoded response data: $responseData');
      
      final List<dynamic> cars = responseData['cars']; // Access the 'cars' list

      // Debugging: Print the list of cars
      print('Cars data: $cars');
      
      return cars;
    } else {
      print('Failed to load user cars: ${response.statusCode} - ${response.body}');
      throw Exception('Failed to load user cars: ${response.body}');
    }
  } catch (e) {
    print('Error fetching user cars: $e');
    return [];
  }
}
Future<List<dynamic>> fetchRecentServices() async {
  try {
    // Get token from shared preferences
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('jwt_token');

    // Check if token is available
    if (token == null) {
      throw Exception('Token is missing!');
    }

    // Make API request
    final response = await http.get(
      Uri.parse('https://expertstrials.xyz/Garifix_app/api/recent_services'), 
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    // Handle response
    if (response.statusCode == 200) {
      // Debugging: Print the raw response body
      print('Response body: ${response.body}');
      
      final Map<String, dynamic> responseData = json.decode(response.body);

      // Debugging: Print the decoded response data
      print('Decoded response data: $responseData');
      
      final List<dynamic> services = responseData['recent_services']; // Access the 'recent_services' list

      // Debugging: Print the list of services
      print('Services data: $services');
      
      return services;
    } else {
      throw Exception('Failed to load recent services: ${response.body}');
    }
  } catch (e) {
    print('Error fetching recent services: $e');
    return [];
  }
}


Future<Map<String, dynamic>> fetchMaintenanceCosts() async {
  try {
    // Fetch token from shared preferences
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');

    if (token == null || token.isEmpty) {
      throw Exception('Authentication token is missing or invalid.');
    }

    // API request
    final response = await http.get(
      Uri.parse('https://expertstrials.xyz/Garifix_app/api/maintenance_costs'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    // Check for response status
    if (response.statusCode == 200) {
      // Parse JSON response
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return data;
    } else {
      // Log error details for non-200 responses
      print('Failed to load maintenance costs: ${response.statusCode} - ${response.body}');
      throw Exception('Failed to load maintenance costs. HTTP status: ${response.statusCode}');
    }
  } catch (e) {
    // Catch any errors during the request or JSON parsing
    print('Error fetching maintenance costs: $e');
    return {'error': e.toString()};
  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.deepPurple,
        elevation: 10,
        title: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.7),
                    blurRadius: 10,
                    spreadRadius: 3,
                  ),
                ],
              ),
              child: Image.asset(
                'assets/logo/app_logo.png',
                height: 50,
                width: 50,
              ),
            ),
            const SizedBox(width: 15),
            ShaderMask(
              shaderCallback: (Rect bounds) {
                return const LinearGradient(
                  colors: [Color.fromARGB(255, 255, 171, 64), Colors.yellow],
                  tileMode: TileMode.mirror,
                ).createShader(bounds);
              },
              child: const Text(
                'Mecar',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            iconSize: 28,
            color: Colors.white,
            splashRadius: 25,
            onPressed: () {
              // Notification action
            },
            tooltip: 'Notifications',
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: fetchMaintenanceData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData) {
            return Center(child: Text("No data available"));
          }

          final maintenanceData = snapshot.data!['maintenanceData'];
          final userCars = snapshot.data!['userCars'];
          final recentServices = snapshot.data!['recentServices'];

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Welcome Back!',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {},
                        icon: Icon(Icons.support_agent, size: 20),
                        label: Text('Seek Support'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),

                  // Maintenance Costs Summary Section
                  Text(
                    'Maintenance Costs Summary:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SummaryCard(
                        label: 'Total Cost',
                        amount: maintenanceData['total_cost'],
                        icon: Icons.attach_money,
                      ),
                      SummaryCard(
                        label: "This Month's Cost",
                        amount: maintenanceData['monthly_cost'],
                        icon: Icons.calendar_today,
                      ),
                    ],
                  ),
                  SizedBox(height: 20),

// User Cars Section
Text(
  'Your Cars:',
  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
),
SizedBox(height: 10),
SizedBox(
  height: 200,
  child: ListView.builder(
    scrollDirection: Axis.horizontal,
    itemCount: userCars.length,
    itemBuilder: (context, index) {
      final car = userCars[index];
      return CarCard(
        carModel: car['car_name'],
        totalCost: (car['total_cost'] != null) ? double.tryParse(car['total_cost'].toString()) ?? 0.0 : 0.0,
        repairDetails: car['repair_details'],
        imageUrl: car['image_path'],
      );
    },
  ),
),
SizedBox(height: 20),

// Recent Services Section
Text(
  'Recent Services:',
  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
),
SizedBox(height: 10),
recentServices.isEmpty
    ? Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          'No recent services available.',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
      )
    : ListView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        itemCount: recentServices.length,
        itemBuilder: (context, index) {
          final service = recentServices[index];
          return ServiceCard(
            serviceName: service['service_name'],
            date: service['date'],
            cost: (service['cost'] != null) ? double.tryParse(service['cost'].toString()) ?? 0.0 : 0.0,
          );
        },
      ),

                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
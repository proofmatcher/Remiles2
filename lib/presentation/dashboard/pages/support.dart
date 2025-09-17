
import 'package:flutter/material.dart';
import 'package:majh/presentation/common/widgets/top_navigation_bar.dart';
class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE0E0E0), // Light grey background as in the image
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              TopNavigationBar(context),
              Padding(
                padding: const EdgeInsets.all(20.0), // Padding around the main card
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [

                    Padding(
                      padding: const EdgeInsets.only(top: 30.0,bottom: 20),
                      child: Text('Support',
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          )),
                    ),
                    // Top rounded card container
                    Container(
                      padding: const EdgeInsets.all(25.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30.0), // Rounded corners for the card
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Introductory text
                           Text(
                            'If you are experiencing any issues, please let us know, We will try to solve them as soon as possible',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 30),

                          // Title field
                          const Text(
                            'Title',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.grey.shade200,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                                borderSide: BorderSide.none, // No border for the text field
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 15.0, horizontal: 15.0),
                            ),
                            maxLines: 1,
                          ),
                          const SizedBox(height: 30),

                          // Explain the problem field
                          const Text(
                            'Explain the problem',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          const SizedBox(height: 10),
                          TextFormField(
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.grey.shade200,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10.0),
                                borderSide: BorderSide.none, // No border for the text field
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 15.0, horizontal: 15.0),
                            ),
                            maxLines: 7, // Multi-line input for description
                            minLines: 5,
                          ),
                          const SizedBox(height: 40),

                          // Submit Button
                          Center(
                            child: ElevatedButton(
                              onPressed: () {
                                // Handle submit action
                                print('Submit button pressed!');
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2C5E4A), // Dark green color
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 60, vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                elevation: 5, // Shadow effect
                              ),
                              child: const Text(
                                'Submit',
                                style: TextStyle(fontSize: 18, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
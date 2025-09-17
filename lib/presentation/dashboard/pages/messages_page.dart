import 'package:flutter/material.dart';
import 'package:majh/presentation/common/widgets/top_navigation_bar.dart';
import 'package:majh/presentation/dashboard/pages/chat_screen.dart';

class MessagesPage extends StatelessWidget {
  const MessagesPage({super.key});

  @override
  Widget build(BuildContext context) {
    const Color containerColor = Color(0xFFF0F0E8);
    const Color iconColor = Color(0xFF1E5B3D);
    const Color hintColor = Colors.grey;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          TopNavigationBar(context),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0,vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 30.0),
                  child: Text('Messages',
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  )),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    5,
                        (index) =>  ListTile(
                          onTap: (){
                            // ChatScreen
                            Navigator.push(context, MaterialPageRoute(builder: (context) => ChatScreen()));

                          },
                          leading: Icon(
                            Icons.person_outline,
                            color: iconColor,
                            size: 36.0,
                          ),
                          title:  Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Bill john",
                                style: TextStyle(
                                  color: hintColor,
                                  fontSize: 16.0,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                              Text(
                                "Hi, im in the vicinity",
                                style: TextStyle(
                                  color: hintColor,
                                  fontSize: 16.0,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                          trailing: Text('12:34'),
                        )
                    ),
                  ),
              ],
            ),
            ),
        ],
      ));
  }
}
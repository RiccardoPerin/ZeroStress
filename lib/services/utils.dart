import 'package:flutter/material.dart';
import '../screens/LoginPage.dart';

Widget buildLogo() {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Image.asset(
            'assets/logo.png',
            height: 100,
          ),
          const SizedBox(width: 10),
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(
                  text: 'Zero',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 50,
                    color: Color(0xFF384242),
                  )
                ),

                const TextSpan(
                  text: 'Stress',
                  style: TextStyle(
                    fontWeight: FontWeight.w200,
                    fontSize: 50,
                    color: LoginPage.primaryAzure,
                  )
                )
              ]
            )
          ),
        ],
      ),
    );
  }


  Widget buildMessage(String message1, String message2) {
    return Column( // Avvolgi tutto in una Column
      crossAxisAlignment: CrossAxisAlignment.start, // Allinea il testo a sinistra
      children: [
        Text(
          message1,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 32,
            color: Color(0xFF384242),
          ),
        ),
        SizedBox(height: 10),
        Text(
          message2,
          style: TextStyle(
            color: Colors.grey,
            fontSize: 16,
          ),
        ),
      ],
    );
  }
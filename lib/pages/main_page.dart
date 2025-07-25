import 'package:calendar_appbar/calendar_appbar.dart';
import 'package:casharoo_app/pages/home_page.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  // final List<Widget> _children = [HomePage(), CategoryPage()];
  int currentIndex = 0;

  void onTapTapped(int index) {
    setState(() {
      currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          (currentIndex == 0)
              ? CalendarAppBar(
                backButton: false,
                accent: Colors.deepPurpleAccent,
                locale: 'en',
                onDateChanged: (value) => print(value),
                firstDate: DateTime.now().subtract(Duration(days: 140)),
                lastDate: DateTime.now(),
              )
              : PreferredSize(
                preferredSize: Size.fromHeight(100),
                child: Padding(
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 16,
                    left: 16,
                    right: 16
                  ),
                  child: Text(
                    "Categories",
                    style: GoogleFonts.roboto(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
      // body: _children[currentIndex],
      body: HomePage(),
      floatingActionButton: Visibility(
        visible: (currentIndex == 0) ? true : false,
        child: FloatingActionButton(
          onPressed: () {
            // Navigator.of(context).push(MaterialPageRoute(
            //   builder: (context) => TransactionPage(),
            // )).then((value) {
            //   setState(() {
                
            //   });
            // });
          },
          backgroundColor: Colors.deepPurpleAccent,
          shape: CircleBorder(),
          child: Icon(Icons.add, color: Colors.white,),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              onPressed: () {
                onTapTapped(0);
              },
              icon: Icon(Icons.home),
            ),
            SizedBox(width: 20),
            IconButton(
              onPressed: () {
                onTapTapped(1);
              },
              icon: Icon(Icons.list),
            ),
          ],
        ),
      ),
    );
  }
}

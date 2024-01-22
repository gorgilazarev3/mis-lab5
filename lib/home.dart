import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mis_lab3/auth_gate.dart';
import 'package:mis_lab3/map.dart';
import 'package:mis_lab3/models/app_data.dart';
import 'package:mis_lab3/models/exam_term.dart';
import 'package:mis_lab3/models/location_based_event.dart';
import 'package:mis_lab3/services/notification_service.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<ExamTerm> examTerms = [
    ExamTerm(
        subjectName: "Веб базирани системи",
        examTerm: new DateTime(2024, 2, 8, 16, 30)),
    ExamTerm(
        subjectName: "Имлементација на системи со слободен и отворен код",
        examTerm: new DateTime(2024, 2, 8, 9, 0))
  ];

  final newExamTermSubjectController = TextEditingController();
  DateTime newExamTermDateTime = DateTime(2024);

  DateTime selectedDay = DateTime.now();
  ValueNotifier<List<ExamTerm>> selectedEvents = ValueNotifier([]);

  @override
  void initState() {
    super.initState();
    selectedEvents = ValueNotifier(examTerms.where((element) => isSameDay(element.examTerm, selectedDay)).toList());
    scheduleEarliestExam();
    addLocationBasedEventsForExams();
  }

  @override
  void dispose() {
    selectedEvents.dispose();
    super.dispose();
  }

  void addLocationBasedEventsForExams() {
    for(ExamTerm term in examTerms) {
      LocationBasedEvent event = LocationBasedEvent(location: LatLng(42.004486, 21.4072295), name: term.subjectName, date: term.examTerm);
      Provider.of<AppData>(context, listen: false).addEvent(event);
    }

  }

  void scheduleEarliestExam() {
    List<ExamTerm> sortedExamsByDate = List.of(examTerms);
    sortedExamsByDate.sort((a, b) => a.examTerm!.compareTo(b.examTerm!),);
      NotificationService().scheduleNotification(
      title: 'Термин за ${sortedExamsByDate[0].subjectName} наскоро!', body: 'Терминот за предметот ${sortedExamsByDate[0].subjectName} е на ${sortedExamsByDate[0].examTerm!.day.toString().padLeft(2, '0')}:${sortedExamsByDate[0].examTerm!.month.toString().padLeft(2, '0')}} во ${sortedExamsByDate[0].examTerm!.hour.toString().padLeft(2, '0')}:${sortedExamsByDate[0].examTerm!.minute.toString().padLeft(2, '0')}h',
            scheduledNotificationDateTime: DateTime(sortedExamsByDate[0].examTerm!.year, sortedExamsByDate[0].examTerm!.month, sortedExamsByDate[0].examTerm!.day - 1, DateTime.now().hour, DateTime.now().minute));
  }

  List<ExamTerm> _getEventsForDay(DateTime day) {
    return examTerms.where((element) => isSameDay(day, element.examTerm)).toList();
  }

  void showCalendar() {
    showDialog(context: context, builder: (context) =>
    StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        content: SizedBox(
                        height: MediaQuery.sizeOf(context).height * 0.6,
              width: MediaQuery.sizeOf(context).height * 0.95,
          child: Column(
            children: [
              TableCalendar<ExamTerm>(
              firstDay: DateTime(2020, 10, 1),
              lastDay: DateTime(2030, 12, 31),
              focusedDay: selectedDay,
              eventLoader: _getEventsForDay,
              selectedDayPredicate: (day) {
              return isSameDay(selectedDay, day);
              },
              onDaySelected: (Day, focusedDay) {
              setState(() {
                this.selectedDay = Day;
                selectedEvents.value = _getEventsForDay(selectedDay);
              });
              },
              ),
            const SizedBox(height: 8.0),
            Expanded(
              child: ValueListenableBuilder<List<ExamTerm>>(
                valueListenable: selectedEvents,
                builder: (context, value, _) {
                  return ListView.builder(
                    itemCount: value.length,
                    itemBuilder: (context, index) {
                      return Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12.0,
                          vertical: 4.0,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(),
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: ListTile(
                          onTap: () {
                            NotificationService().showNotification(title: 'Термин за ${value[index].subjectName}', body: 'Терминот за предметот ${value[index].subjectName} е на ${value[index].examTerm!.day.toString().padLeft(2, '0')}:${value[index].examTerm!.month.toString().padLeft(2, '0')}} во ${value[index].examTerm!.hour.toString().padLeft(2, '0')}:${value[index].examTerm!.minute.toString().padLeft(2, '0')}h');
                          },
                          title: Text('${value[index].subjectName} - ${value[index].examTerm!.hour.toString().padLeft(2, '0')}:${value[index].examTerm!.minute.toString().padLeft(2, '0')}'),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            ],
          ),
        ),
      ),
    )
    );
  }

  void showNewTermDialog() {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
            content: SizedBox(
                height: MediaQuery.sizeOf(context).height * 0.35,
                width: MediaQuery.sizeOf(context).width * 0.9,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 25),
                      child: TextFormField(
                        controller: newExamTermSubjectController,
                        // style: TextStyle(color: Colors.lightBlue),
                        decoration: const InputDecoration(
                            border: UnderlineInputBorder(),
                            hintText: 'Внесете го името на предметот',
                            hintStyle: TextStyle(color: Colors.teal)),
                      ),
                    ),
                    ElevatedButton(
                        onPressed: () {
                          showDatePicker(
  context: context,
  initialDate: DateTime.now(),
  firstDate: DateTime(2020),
  lastDate: DateTime(2031),
).then((selectedDate) {
  // After selecting the date, display the time picker.
  if (selectedDate != null) {
    showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    ).then((selectedTime) {
      // Handle the selected date and time here.
      if (selectedTime != null) {
        DateTime selectedDateTime = DateTime(
          selectedDate.year,
          selectedDate.month,
          selectedDate.day,
          selectedTime.hour,
          selectedTime.minute,
        );
        newExamTermDateTime = selectedDateTime; // You can use the selectedDateTime as needed.
      }
    });
  }
});
                          // DateTimePicker.DatePicker.showDateTimePicker(context,
                          //     showTitleActions: true,
                          //     minTime: DateTime(2023, 10, 1),
                          //     maxTime: DateTime(2024, 12, 31),
                          //     onChanged: (date) {
                          //   newExamTermDateTime = date;
                          // }, onConfirm: (date) {
                          //   newExamTermDateTime = date;
                          // },
                          //     currentTime: DateTime.now(),
                          //     locale: DateTimePicker.LocaleType.en);
                        },
                        child: const Text(
                          'Избери време и датум на одржување на терминот',
                          style: TextStyle(color: Colors.teal),
                        )),
                    Padding(
                      padding: const EdgeInsets.all(50),
                      child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              this.examTerms.add(ExamTerm(
                                  subjectName: newExamTermSubjectController.text,
                                  examTerm: newExamTermDateTime));
                              Navigator.pop(context);
                              newExamTermSubjectController.text = "";
                              newExamTermDateTime = DateTime(2024);
                            });
                          },
                          child: Text(
                            'Додади',
                            style: TextStyle(color: Colors.teal),
                          )),
                    )
                  ],
                ))));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton:FloatingActionButton(onPressed: () {
                 Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: ((context) => MapWidget())));
      }, child: const Icon(Icons.map_outlined, color: Colors.white,),
      backgroundColor: Colors.teal,),
      appBar: AppBar(
        title: Text(
          FirebaseAuth.instance.currentUser != null
              ? FirebaseAuth.instance.currentUser?.email ??
                  "Логирајте се за да додадете термин"
              : "Логирајте се за да додадете термин",
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        actions: [
          FirebaseAuth.instance.currentUser != null
              ? Row(
                  children: [
                    IconButton(onPressed: () {
                      showCalendar();
                    }, icon: const Icon(Icons.calendar_month_outlined, color: Colors.white)),
                    IconButton(
                        onPressed: () {
                          this.showNewTermDialog();
                        },
                        icon: const Icon(Icons.add_box, color: Colors.white)),
                    IconButton(
                        onPressed: () async {
                          await FirebaseAuth.instance.signOut();
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: ((context) => HomeScreen())));
                        },
                        icon: const Icon(Icons.logout_outlined,
                            color: Colors.white))
                  ],
                )
              : IconButton(
                  onPressed: () async {
                    Navigator.push(context,
                        MaterialPageRoute(builder: ((context) => AuthGate())));
                  },
                  icon: const Icon(Icons.login_outlined, color: Colors.white))
        ],
      ),
      body: Column(
        children: [
          GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8.0,
              mainAxisSpacing: 8.0,
            ),
            itemCount: this.examTerms.length,
            itemBuilder: (BuildContext context, int index) {
              return Card(
                child: Column(
                  children: [
                    Flexible(
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Center(
                            child: Text(
                          this.examTerms[index].subjectName ?? "",
                          style: TextStyle(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        )),
                      ),
                    ),
                    Flexible(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 13),
                        child: Text(
                          this
                              .examTerms[index]
                              .examTerm
                              .toString()
                              .split(".")[0],
                          style: TextStyle(
                              color: const Color.fromARGB(255, 83, 83, 83)),
                        ),
                      ),
                    ),
                    IconButton(onPressed: () {
                      this.setState(() {
                        this.examTerms.removeAt(index);
                      });
                      
                    }, icon: Icon(Icons.remove_circle, color: Colors.red,))
                  ],
                  crossAxisAlignment: CrossAxisAlignment.center,
                ),
                margin: const EdgeInsets.all(10),
              );
            },
            shrinkWrap: true,
          ),
        ],
      ),
    );
  }
}

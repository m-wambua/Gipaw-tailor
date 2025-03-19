import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:gipaw_tailor/signinpage/authorization.dart';
import 'package:gipaw_tailor/signinpage/protectedroutes.dart';
import 'package:gipaw_tailor/signinpage/users.dart';
import 'package:gipaw_tailor/uniforms/uniforms_data.dart';
import 'package:provider/provider.dart';

class UniformOrderDirective extends StatefulWidget {
  const UniformOrderDirective({Key? key}) : super(key: key);

  _UniformOrderDirectiveState createState() => _UniformOrderDirectiveState();
}

class _UniformOrderDirectiveState extends State<UniformOrderDirective>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ProtectedRoute(
        allowedRoles: const [UserRole.admin, UserRole.manager],
        child: Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                const Text("Uniform Order Directive"),
              ],
            ),
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(
                  text: "Pending Order",
                ),
                Tab(
                  text: "Completed But Waiting Approval",
                ),
                Tab(
                  text: "Approved and Verified Orders",
                )
              ],
            ),
          ),
          body: TabBarView(controller: _tabController, children: [
            const PendingOrderTab(),
            const WaitingApprovalTab(),
            const ApprovedandVerifiedTab(),
          ]),
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              _uniformOrders();
            },
            tooltip: "make new order",
            child: const Icon(Icons.add),
          ),
        ));
  }

  Future<void> _uniformOrders() async {
    final uniformItems = uniformItemData.keys.toList();
    List<Map<String, dynamic>> entries = [];
    showDialog(
        context: context,
        builder: (BuildContext contetx) {
          return StatefulBuilder(builder: (context, setState) {
            return AlertDialog(
              title: const Text('Uniform Order Directive'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                        child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: entries.length,
                            itemBuilder: (context, index) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8.0),
                                    child: Row(
                                      children: [
                                        Flexible(
                                            child: DropdownButtonFormField<
                                                    String>(
                                                decoration:
                                                    const InputDecoration(
                                                        labelText:
                                                            "Uniform Item"),
                                                items: uniformItems
                                                    .map((String item) {
                                                  return DropdownMenuItem<
                                                          String>(
                                                      value: item,
                                                      child: Text(item));
                                                }).toList(),
                                                onChanged: (String? newValue) {
                                                  entries[index][
                                                          'selectedUniformItem'] =
                                                      newValue;
                                                  entries[index]
                                                          ['availableColors'] =
                                                      uniformItemData[
                                                          newValue]!['colors']!;
                                                  entries[index]
                                                          ['availableSizes'] =
                                                      uniformItemData[
                                                          newValue]!['sizes']!;
                                                  entries[index]
                                                      ['selectedSize'] = null;
                                                  entries[index]
                                                      ['selectedColor'] = null;
                                                },
                                                value: entries[index]
                                                    ['selectedUniformItem'])),
                                        const SizedBox(
                                          width: 10,
                                        ),
                                        Expanded(
                                            child:
                                                DropdownButtonFormField<String>(
                                          decoration: const InputDecoration(
                                              labelText: "Color"),
                                          items: entries[index]
                                                  ['availableColors']
                                              .map<DropdownMenuItem<String>>(
                                                  (color) {
                                            return DropdownMenuItem<String>(
                                                value: color,
                                                child: Text(color));
                                          }).toList(),
                                          onChanged: (String? newValue) {
                                            setState(() {
                                              entries[index]['selectedColor'] =
                                                  newValue;
                                            });
                                          },
                                          value: entries[index]
                                              ['selectedColor'],
                                        )),
                                        const SizedBox(
                                          width: 10,
                                        ),
                                        Expanded(
                                            child:
                                                DropdownButtonFormField<String>(
                                          decoration: const InputDecoration(
                                              labelText: "Size"),
                                          items: entries[index]
                                                  ['availableSizes']
                                              .map<DropdownMenuItem<String>>(
                                                  (size) {
                                            return DropdownMenuItem<String>(
                                              value: size,
                                              child: Text(size),
                                            );
                                          }).toList(),
                                          onChanged: (String? newValue) {
                                            setState(() {
                                              entries[index]['selectedSize'] =
                                                  newValue;
                                            });
                                          },
                                          value: entries[index]['selectedSize'],
                                        )),
                                        const SizedBox(
                                          width: 10,
                                        ),
                                        Expanded(
                                            child: TextFormField(
                                          controller: entries[index]
                                              ['numberController'],
                                          decoration: const InputDecoration(
                                              labelText: "Number"),
                                          keyboardType: TextInputType.number,
                                          validator: (value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return "Enter a number";
                                            }
                                            if (int.tryParse(value) == null) {
                                              return "Only whole numbers allowed";
                                            }
                                            return null;
                                          },
                                        )),
                                        IconButton(
                                            onPressed: () => _removeEntry(
                                                entries, index, setState),
                                            icon: const Icon(
                                              Icons.remove_circle,
                                              color: Colors.red,
                                            ))
                                      ],
                                    ),
                                  )
                                ],
                              );
                            })),
                    const SizedBox(
                      height: 10,
                    ),
                    TextButton.icon(
                      icon: const Icon(
                        Icons.add,
                        color: Colors.green,
                      ),
                      label: const Text("Add"),
                      onPressed: () => _addNewEntry(entries, setState),
                    )
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () {}, child: const Text("Send Order")),
                TextButton(onPressed: () {}, child: const Text("Cancel"))
              ],
            );
          });
        });
  }

  void _addNewEntry(List<Map<String, dynamic>> entries, Function setState) {
    setState(() {
      entries.add({
        'selectedUniformItem': null,
        'selectedColor': null,
        'selectedSize': null,
        'availableColors': [],
        'availableSizes': [],
        'numberController': TextEditingController(),
      });
    });
  }

  void _removeEntry(
      List<Map<String, dynamic>> entries, int index, Function setState) {
    setState(() {
      entries.removeAt(index);
    });
  }
}

class PendingOrderTab extends StatelessWidget {
  const PendingOrderTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold();
  }
}

class WaitingApprovalTab extends StatelessWidget {
  const WaitingApprovalTab({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold();
  }
}

class ApprovedandVerifiedTab extends StatelessWidget {
  const ApprovedandVerifiedTab({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold();
  }
}

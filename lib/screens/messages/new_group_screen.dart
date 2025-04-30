import 'package:flutter/material.dart';

class NewGroupScreen extends StatefulWidget {
  const NewGroupScreen({super.key});

  @override
  State<NewGroupScreen> createState() => _NewGroupScreenState();
}

class _NewGroupScreenState extends State<NewGroupScreen> {
  final TextEditingController groupNameController = TextEditingController();
  final TextEditingController searchController = TextEditingController();

  final List<Map<String, String>> suggestions = List.generate(10, (index) => {
    'avatar': 'https://i.pravatar.cc/150?img=$index',
    'name': 'User $index',
    'username': 'user$index',
  });

  final Set<int> selectedIndexes = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Nhóm chat mới'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: groupNameController,
              decoration: InputDecoration(
                hintText: 'Tên nhóm (không bắt buộc)',
                filled: true,
                fillColor: Colors.grey[850],
                contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 15),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm',
                prefixIcon: Icon(Icons.search, size: 20),
                filled: true,
                fillColor: Colors.grey[850],
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() {

                });
              },
            ),
            SizedBox(height: 15),
            if (selectedIndexes.isNotEmpty)
              SizedBox(
                height: 90,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: selectedIndexes.map((index) {
                    final account = suggestions[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Column(
                        children: [
                          Stack(
                            children: [
                              CircleAvatar(
                                backgroundImage: NetworkImage(account['avatar']!),
                                radius: 28,
                              ),
                              Positioned(
                                right: -4,
                                top: -4,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      selectedIndexes.remove(index);
                                    });
                                  },
                                  child: CircleAvatar(
                                    radius: 10,
                                    backgroundColor: Colors.red,
                                    child: Icon(Icons.close, size: 14, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            account['username']!,
                            style: TextStyle(fontSize: 10),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            SizedBox(height: 12),
            Text('Gợi ý', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: suggestions.length,
                itemBuilder: (context, index) {
                  final account = suggestions[index];
                  final isSelected = selectedIndexes.contains(index);
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage: NetworkImage(account['avatar']!),
                    ),
                    title: Text(account['name']!),
                    subtitle: Text(account['username']!),
                    trailing: Checkbox(
                      value: isSelected,
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            selectedIndexes.add(index);
                          } else {
                            selectedIndexes.remove(index);
                          }
                        });
                      },
                    ),
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          selectedIndexes.remove(index);
                        } else {
                          selectedIndexes.add(index);
                        }
                      });
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: selectedIndexes.length >= 3
          ? Padding(
        padding: const EdgeInsets.all(10),
        child: SizedBox(
          height: 40,
          child: FloatingActionButton.extended(
            onPressed: () {
              print('Tạo nhóm với: $selectedIndexes');
            },
            icon: Icon(Icons.group_add, size: 18),
            label: Text(
              'Tạo nhóm chat',
              style: TextStyle(fontSize: 14),
            ),
            backgroundColor: Colors.blue,
          ),
        ),
      )
          : null,

    );
  }
}

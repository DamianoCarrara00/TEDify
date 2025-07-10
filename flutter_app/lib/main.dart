import 'package:flutter/material.dart';
import 'talk_repository.dart';
import 'models/talk.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TEDify',
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, this.title = 'TEDify'});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final TextEditingController _tagController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  List<Talk> _tagTalks = [];
  List<Talk2> _idTalks = [];
  bool _isLoading = false;
  int page = 1;
  final String _currentUserId = "user_test";

  void _getTalksByTag() async {
    if (_tagController.text.isEmpty) return;
    setState(() {
      _isLoading = true;
      _idTalks = []; // Pulisce i risultati dell'altra ricerca
    });

    try {
      final talks = await getTalksByTag(_tagController.text, page);
      setState(() {
        _tagTalks = talks;
      });
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      setState(() {
        _isLoading = false;
      });
      _tagController.clear();
    }
  }

  void _getTalksById() async {
    if (_idController.text.isEmpty) return;
    setState(() {
      _isLoading = true;
      _tagTalks = []; // Pulisce i risultati dell'altra ricerca
    });

    try {
  final talks = await getTalksById(_idController.text, page);

  if (talks.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Watch next non presenti nel dataset.')),
    );
  }

  setState(() {
    _idTalks = talks;
  });
} catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Errore: ${e.toString()}')),
  );
} finally {
      setState(() {
        _isLoading = false;
      });
      _idController.clear();
    }
  }

  void _toggleLike(String talkId, bool isLiked, {Talk? tagTalk, Talk2? idTalk}) async {
    
    setState(() {
      if (tagTalk != null) {
        if (isLiked) {
          tagTalk.likes.remove(_currentUserId);
        } else {
          tagTalk.likes.add(_currentUserId);
        }
      } else if (idTalk != null) {
        if (isLiked) {
          idTalk.likes.remove(_currentUserId);
        } else {
          idTalk.likes.add(_currentUserId);
        }
      }
    });

    // Chiamata API
    try {
      print('Video ID: $talkId, User ID: $_currentUserId');
      await likeUnlikeTalk(talkId, _currentUserId);
    } catch (e) {
      // Rollback in caso di errore
      setState(() {
         if (tagTalk != null) {
          if (isLiked) {
            tagTalk.likes.add(_currentUserId);
          } else {
            tagTalk.likes.remove(_currentUserId);
          }
        } else if (idTalk != null) {
          if (isLiked) {
            idTalk.likes.add(_currentUserId);
          } else {
            idTalk.likes.remove(_currentUserId);
          }
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update like. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        toolbarHeight: 100,
        title: Row(
          children: [
            Image.asset(
              'assets/images/Logo_TEDify.png',
              height: 80,
            ),
            const SizedBox(width: 80),
            Text(
              widget.title,
              style: const TextStyle(
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: <Widget>[
          TextField(
            controller: _tagController,
            decoration:
                const InputDecoration(hintText: 'Enter your favorite topic'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Search by tag'),
            onPressed: () {
              _getTalksByTag();
            },
          ),
          TextField(
            controller: _idController,
            decoration: const InputDecoration(
                hintText: 'Enter the id of the talk you saw'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Search by ID'),
            onPressed: () {
              _getTalksById();
            },
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(),
            )
          else
            Expanded(
              child: ListView.builder(
                // La lista viene costruita dinamicamente a seconda di quale ricerca è stata fatta
                itemCount: _tagTalks.isNotEmpty ? _tagTalks.length : _idTalks.length,
                itemBuilder: (context, index) {
                  if (_tagTalks.isNotEmpty) {
                    final talk = _tagTalks[index];
                    final isLiked = talk.likes.contains(_currentUserId);
                    return ListTile(
                      title: Text(talk.title),
                      subtitle: Text(talk.mainSpeaker),
                      trailing: IconButton(
                        icon: Icon(
                          isLiked ? Icons.favorite : Icons.favorite_border,
                          color: isLiked ? Colors.red : Colors.grey,
                        ),
                        onPressed: () => _toggleLike(talk.id, isLiked, tagTalk: talk),
                      ),
                      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(talk.details)),
                      ),
                    );
                  } else if (_idTalks.isNotEmpty) {
                    final talk = _idTalks[index];
                    final isLiked = talk.likes.contains(_currentUserId);
                    return ListTile(
                      title: Text(talk.title),
                      subtitle: Text(talk.mainSpeaker),
                      trailing: IconButton(
                        icon: Icon(
                          isLiked ? Icons.favorite : Icons.favorite_border,
                          color: isLiked ? Colors.red : Colors.grey,
                        ),
                        onPressed: () => _toggleLike(talk.id, isLiked, idTalk: talk),
                      ),
                      onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(talk.details)),
                      ),
                    );
                  }
                  return const SizedBox.shrink(); // Non dovrebbe mai accadere
                },
              ),
            ),
        ],
      ),
      /*floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: (!init)
          ? FloatingActionButton(
              child: const Icon(Icons.arrow_drop_down),
              onPressed: () {
                setState(() {
                  page += 1;
                  _getTalksByTag();
                });
              },
            )
          : null,*/
      bottomNavigationBar: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.0),
          color: Colors.red,
        ),
        child: SizedBox(
          height: 60.0,
          width: MediaQuery.of(context).size.width * 0.8,
          child: Row(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              IconButton(
                icon: const Icon(Icons.home, color: Colors.black),
                onPressed: () {
                  setState(() {
                    _tagTalks = [];
                    _idTalks = [];
                    _tagController.clear();
                    _idController.clear();
                    page = 1;
                  });
                },
              ),
              IconButton(
                icon: const Icon(Icons.search, color: Colors.black),
                onPressed: () {
                  // Actions to perform when search icon is pressed
                },
              ),
              IconButton(
                onPressed: () {/*
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => LoginPage(
                              page: page,
                              initTag: initTag.toString(),
                              initIdDart: initIdDart.toString(),
                            )),
                  );*/
                },
                icon: CircleAvatar(
                  radius: 15,
                  backgroundColor: Colors.white,
                  child: Image.asset('assets/images/User_Pic.jpg'),
                ),
              ),
            ],
          ),
        ),
    )
    );
  }
}
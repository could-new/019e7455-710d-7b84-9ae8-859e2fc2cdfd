import 'package:flutter/material.dart';

void main() {
  runApp(const ResumeBuilderApp());
}

class ResumeBuilderApp extends StatelessWidget {
  const ResumeBuilderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Resume Builder',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueGrey),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomeScreen(),
      },
    );
  }
}

// --- MODELS ---

class Resume {
  String id;
  String fullName;
  String email;
  String phone;
  String summary;
  List<Experience> experiences;
  List<Education> education;

  Resume({
    required this.id,
    required this.fullName,
    required this.email,
    required this.phone,
    required this.summary,
    required this.experiences,
    required this.education,
  });

  factory Resume.empty() {
    return Resume(
      id: '',
      fullName: '',
      email: '',
      phone: '',
      summary: '',
      experiences: [],
      education: [],
    );
  }

  Resume copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phone,
    String? summary,
    List<Experience>? experiences,
    List<Education>? education,
  }) {
    return Resume(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      summary: summary ?? this.summary,
      experiences: experiences ?? this.experiences,
      education: education ?? this.education,
    );
  }
}

class Experience {
  String id;
  String company;
  String role;
  String duration;
  String description;

  Experience({
    required this.id,
    required this.company,
    required this.role,
    required this.duration,
    required this.description,
  });
}

class Education {
  String id;
  String institution;
  String degree;
  String year;

  Education({
    required this.id,
    required this.institution,
    required this.degree,
    required this.year,
  });
}

// --- BACKEND SERVICE (SIMULATED) ---

class BackendService {
  static final BackendService _instance = BackendService._internal();
  factory BackendService() => _instance;
  BackendService._internal();

  final List<Resume> _db = [
    Resume(
      id: '1',
      fullName: 'Jane Doe',
      email: 'jane.doe@example.com',
      phone: '+1 555-0198',
      summary: 'Experienced Flutter developer with a passion for building beautiful, responsive cross-platform applications.',
      experiences: [
        Experience(id: 'e1', company: 'Tech Corp', role: 'Senior Developer', duration: '2020 - Present', description: 'Lead mobile app development.'),
      ],
      education: [
        Education(id: 'ed1', institution: 'State University', degree: 'B.S. Computer Science', year: '2019'),
      ],
    )
  ];

  Future<List<Resume>> fetchResumes() async {
    await Future.delayed(const Duration(milliseconds: 800)); // Simulate network
    return List.from(_db);
  }

  Future<void> saveResume(Resume resume) async {
    await Future.delayed(const Duration(milliseconds: 800)); // Simulate network
    if (resume.id.isEmpty) {
      resume.id = DateTime.now().millisecondsSinceEpoch.toString();
      _db.add(resume);
    } else {
      final index = _db.indexWhere((r) => r.id == resume.id);
      if (index != -1) {
        _db[index] = resume;
      }
    }
  }

  Future<void> deleteResume(String id) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _db.removeWhere((r) => r.id == id);
  }
}

// --- UI SCREENS ---

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final BackendService _backend = BackendService();
  List<Resume> _resumes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadResumes();
  }

  Future<void> _loadResumes() async {
    setState(() => _isLoading = true);
    final data = await _backend.fetchResumes();
    setState(() {
      _resumes = data;
      _isLoading = false;
    });
  }

  void _openEditor([Resume? resume]) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditResumeScreen(resume: resume),
      ),
    );
    if (result == true) {
      _loadResumes();
    }
  }

  void _viewResume(Resume resume) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ViewResumeScreen(resume: resume),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Resumes'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _resumes.isEmpty
              ? const Center(child: Text('No resumes found. Create one!'))
              : ListView.builder(
                  itemCount: _resumes.length,
                  itemBuilder: (context, index) {
                    final resume = _resumes[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: const CircleAvatar(child: Icon(Icons.description)),
                        title: Text(resume.fullName.isEmpty ? 'Untitled Resume' : resume.fullName),
                        subtitle: Text(resume.email),
                        onTap: () => _viewResume(resume),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _openEditor(resume),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () async {
                                await _backend.deleteResume(resume.id);
                                _loadResumes();
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.add),
        label: const Text('New Resume'),
      ),
    );
  }
}

class EditResumeScreen extends StatefulWidget {
  final Resume? resume;
  const EditResumeScreen({super.key, this.resume});

  @override
  State<EditResumeScreen> createState() => _EditResumeScreenState();
}

class _EditResumeScreenState extends State<EditResumeScreen> {
  final _formKey = GlobalKey<FormState>();
  late Resume _currentResume;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _currentResume = widget.resume?.copyWith() ?? Resume.empty();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    
    setState(() => _isSaving = true);
    await BackendService().saveResume(_currentResume);
    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.resume == null ? 'Create Resume' : 'Edit Resume'),
        actions: [
          _isSaving 
            ? const Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
              )
            : IconButton(
                icon: const Icon(Icons.save),
                onPressed: _save,
              )
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('Personal Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextFormField(
              initialValue: _currentResume.fullName,
              decoration: const InputDecoration(labelText: 'Full Name', border: OutlineInputBorder()),
              validator: (v) => v!.isEmpty ? 'Required' : null,
              onSaved: (v) => _currentResume.fullName = v!,
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: _currentResume.email,
              decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
              onSaved: (v) => _currentResume.email = v ?? '',
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: _currentResume.phone,
              decoration: const InputDecoration(labelText: 'Phone', border: OutlineInputBorder()),
              onSaved: (v) => _currentResume.phone = v ?? '',
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: _currentResume.summary,
              decoration: const InputDecoration(labelText: 'Professional Summary', border: OutlineInputBorder()),
              maxLines: 3,
              onSaved: (v) => _currentResume.summary = v ?? '',
            ),
            const SizedBox(height: 24),
            // For a real app, Experience and Education would have complex sub-forms.
            // Keeping it simple here.
            const Text('Experience & Education are edited in advanced mode (simplified for demo).', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class ViewResumeScreen extends StatelessWidget {
  final Resume resume;
  const ViewResumeScreen({super.key, required this.resume});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Resume Preview')),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ListView(
            padding: const EdgeInsets.all(32),
            children: [
              Text(resume.fullName, style: Theme.of(context).textTheme.displaySmall),
              const SizedBox(height: 8),
              Text('${resume.email} • ${resume.phone}', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[700])),
              const Divider(height: 32),
              
              if (resume.summary.isNotEmpty) ...[
                Text('Summary', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(resume.summary),
                const SizedBox(height: 24),
              ],

              if (resume.experiences.isNotEmpty) ...[
                Text('Experience', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                ...resume.experiences.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e.role, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('${e.company} | ${e.duration}', style: TextStyle(color: Colors.grey[600])),
                      const SizedBox(height: 4),
                      Text(e.description),
                    ],
                  ),
                )),
                const SizedBox(height: 12),
              ],

              if (resume.education.isNotEmpty) ...[
                Text('Education', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                ...resume.education.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e.degree, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('${e.institution} | ${e.year}', style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                )),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

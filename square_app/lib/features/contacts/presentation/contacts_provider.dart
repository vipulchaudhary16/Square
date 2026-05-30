import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/contact_model.dart';
import '../data/contacts_repository.dart';

final contactsRepositoryProvider = Provider((_) => ContactsRepository());

final contactsProvider =
    AsyncNotifierProvider<ContactsNotifier, List<Contact>>(
        ContactsNotifier.new);

class ContactsNotifier extends AsyncNotifier<List<Contact>> {
  @override
  Future<List<Contact>> build() => _fetch();

  Future<List<Contact>> _fetch() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    return ref.read(contactsRepositoryProvider).getContacts(token);
  }

  Future<Contact> create({
    required String name,
    String? phone,
    String? email,
    String? linkedUserId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    final contact = await ref.read(contactsRepositoryProvider).createContact(
          token,
          name: name,
          phone: phone,
          email: email,
          linkedUserId: linkedUserId,
        );
    final current =
        state is AsyncData<List<Contact>> ? state.requireValue : <Contact>[];
    state = AsyncData([...current, contact]);
    return contact;
  }
}

final contactSearchProvider = FutureProvider.family<ContactSearchResult, String>(
  (ref, query) async {
    if (query.length < 2) {
      return ContactSearchResult(contacts: [], platformUsers: []);
    }
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    return ref.read(contactsRepositoryProvider).search(token, query);
  },
);

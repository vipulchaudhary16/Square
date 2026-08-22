import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../data/contact_model.dart';
import '../data/contacts_repository.dart';

final contactsRepositoryProvider = Provider(
  (ref) => ContactsRepository(ref.watch(apiClientProvider)),
);

final contactsProvider = AsyncNotifierProvider<ContactsNotifier, List<Contact>>(
  ContactsNotifier.new,
);

class ContactsNotifier extends AsyncNotifier<List<Contact>> {
  @override
  Future<List<Contact>> build() =>
      ref.read(contactsRepositoryProvider).getContacts();

  Future<Contact> create({
    required String name,
    String? phone,
    String? email,
    String? linkedUserId,
  }) async {
    final contact = await ref
        .read(contactsRepositoryProvider)
        .createContact(
          name: name,
          phone: phone,
          email: email,
          linkedUserId: linkedUserId,
        );
    final current = state is AsyncData<List<Contact>>
        ? state.requireValue
        : <Contact>[];
    state = AsyncData([...current, contact]);
    return contact;
  }

  Future<Contact> updateContact(
    String contactId, {
    required String name,
    String? phone,
    String? email,
  }) async {
    final updated = await ref
        .read(contactsRepositoryProvider)
        .updateContact(contactId, name: name, phone: phone, email: email);
    final current = state is AsyncData<List<Contact>>
        ? state.requireValue
        : <Contact>[];
    state = AsyncData(
      current.map((c) => c.id == contactId ? updated : c).toList(),
    );
    return updated;
  }
}

final contactSearchProvider =
    FutureProvider.family<ContactSearchResult, String>((ref, query) async {
      if (query.length < 2) {
        return ContactSearchResult(contacts: [], platformUsers: []);
      }
      return ref.read(contactsRepositoryProvider).search(query);
    });

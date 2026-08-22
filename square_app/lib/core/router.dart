import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/presentation/auth_screen.dart';
import '../../features/dashboard/presentation/dashboard_screen.dart';
import '../../shared/widgets/app_layout.dart';
import '../../features/expense/presentation/screens/add_edit_expense_screen.dart';
import '../../features/expense/presentation/screens/expense_detail_screen.dart';
import '../../features/transactions/presentation/transactions_screen.dart';
import '../../features/transactions/presentation/screens/add_edit_income_screen.dart';
import '../../features/transactions/presentation/screens/add_edit_investment_screen.dart';
import '../../features/transactions/presentation/screens/add_edit_loan_screen.dart';
import '../../features/transactions/presentation/screens/transaction_drilldown_screen.dart';
import '../../features/transactions/presentation/widgets/period_selection.dart';
import '../../features/expense/data/expense_model.dart';
import '../../features/transactions/data/loan_model.dart';
import '../../features/contacts/data/contact_model.dart';
import '../../features/auth/presentation/auth_provider.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/feature_flags/presentation/features_settings_screen.dart';
import '../../features/categories/presentation/categories_settings_screen.dart';
import '../../features/groups/presentation/screens/groups_screen.dart';
import '../../features/groups/presentation/screens/create_group_screen.dart';
import '../../features/groups/presentation/screens/group_details_screen.dart';
import '../../features/contacts/presentation/screens/contacts_screen.dart';
import '../../features/contacts/presentation/screens/add_contact_screen.dart';
import '../../features/contacts/presentation/screens/contact_detail_screen.dart';
import '../../features/loans/presentation/loan_detail_screen.dart';

// Keys for navigation
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/dashboard',
    redirect: (context, state) {
      final isLoggedIn = authState.value != null;
      final isAuthRoute = state.uri.path == '/auth';

      if (!isLoggedIn && !isAuthRoute) {
        return '/auth';
      }

      if (isLoggedIn && isAuthRoute) {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/auth', builder: (context, state) => const AuthScreen()),
      // Full-screen routes that render above the shell (no bottom nav)
      GoRoute(
        path: '/groups/create',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CreateGroupScreen(),
      ),
      GoRoute(
        path: '/profile/features',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const FeaturesSettingsScreen(),
      ),
      GoRoute(
        path: '/profile/categories',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CategoriesSettingsScreen(),
      ),
      GoRoute(
        path: '/contacts/add',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AddContactScreen(),
      ),
      GoRoute(
        path: '/contacts/:id/edit',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final contact = state.extra as Contact;
          return AddContactScreen(contact: contact);
        },
      ),
      GoRoute(
        path: '/contacts/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) =>
            ContactDetailScreen(contactId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/loans/:id',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) =>
            LoanDetailScreen(loanId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/loans/:id/edit',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final loan = state.extra as Loan;
          return AddEditLoanScreen(loan: loan);
        },
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return AppLayout(state: state, child: child);
        },
        routes: [
          GoRoute(
            path: '/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/transactions',
            builder: (context, state) => const TransactionsScreen(),
            routes: [
              GoRoute(
                path: 'add-expense',
                builder: (context, state) {
                  final extra = state.extra as Map<String, dynamic>? ?? {};
                  final groupId = extra['groupId'] as String?;
                  return AddEditExpenseScreen(preselectedGroupId: groupId);
                },
              ),
              GoRoute(
                path: 'add-income',
                builder: (context, state) => const AddEditIncomeScreen(),
              ),
              GoRoute(
                path: 'add-investment',
                builder: (context, state) => const AddEditInvestmentScreen(),
              ),
              GoRoute(
                path: 'add-loan',
                builder: (context, state) => const AddEditLoanScreen(),
              ),
              GoRoute(
                path: 'edit',
                builder: (context, state) {
                  final expense = state.extra as Expense;
                  return AddEditExpenseScreen(expense: expense);
                },
              ),
              GoRoute(
                path: 'expenses/:id',
                builder: (context, state) =>
                    ExpenseDetailScreen(expenseId: state.pathParameters['id']!),
              ),
              GoRoute(
                path: 'analysis-detail',
                builder: (context, state) {
                  final extra = state.extra as Map<String, dynamic>;
                  return TransactionDrilldownScreen(
                    isSpending: extra['isSpending'] as bool,
                    period: extra['period'] as PeriodSelection,
                    groupId: extra['groupId'] as String?,
                    allGroupExpenses: extra['allGroupExpenses'] as bool? ?? false,
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: '/reports',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('Reports Placeholder')),
            ),
          ),
          GoRoute(
            path: '/groups',
            builder: (context, state) => const GroupsScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (context, state) {
                  final id = state.pathParameters['id']!;
                  return GroupDetailsScreen(groupId: id);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/expenses/:id',
            builder: (context, state) =>
                ExpenseDetailScreen(expenseId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '/contacts',
            builder: (context, state) => const ContactsScreen(),
          ),
        ],
      ),
    ],
  );
});

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
import '../../features/expense/data/expense_model.dart';
import '../../features/auth/presentation/auth_provider.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/groups/presentation/screens/groups_screen.dart';
import '../../features/groups/presentation/screens/create_group_screen.dart';
import '../../features/groups/presentation/screens/group_details_screen.dart';

// Keys for navigation
final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/dashboard',
    refreshListenable: authState.asData?.value != null
        ? null
        : null, // Helper if needed
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
          // Placeholders for other routes to prevent crashes if clicked in nav
          GoRoute(
            path: '/transactions', // Changed from /expenses
            builder: (context, state) => const TransactionsScreen(),
            routes: [
              GoRoute(
                path: 'add-expense', // /transactions/add-expense
                builder: (context, state) {
                  final extra = state.extra as Map<String, dynamic>? ?? {};
                  final groupId = extra['groupId'] as String?;
                  return AddEditExpenseScreen(preselectedGroupId: groupId);
                },
              ),
              GoRoute(
                path: 'add-income', // /transactions/add-income
                builder: (context, state) => const AddEditIncomeScreen(),
              ),
              GoRoute(
                path: 'add-investment', // /transactions/add-investment
                builder: (context, state) => const AddEditInvestmentScreen(),
              ),
              GoRoute(
                path: 'add-loan', // /transactions/add-loan
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
                path:
                    'expenses/:id', // Explicitly nested for clarity: /transactions/expenses/:id
                builder: (context, state) {
                  final expense = state.extra as Expense;
                  return ExpenseDetailScreen(expense: expense);
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
                path: 'create',
                parentNavigatorKey: _rootNavigatorKey, // Full screen for create
                builder: (context, state) => const CreateGroupScreen(),
              ),
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
            builder: (context, state) {
              final expense = state.extra as Expense;
              return ExpenseDetailScreen(expense: expense);
            },
          ),
        ],
      ),
    ],
  );
});

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:howpa_nurse/features/bottom_bar/presentation/cubit/bottom_nav_bar_cubit.dart';
import 'package:howpa_nurse/features/bottom_bar/presentation/cubit/bottom_nav_bar_state.dart';
import 'package:howpa_nurse/features/bottom_bar/presentation/widgets/custom_bottom_bar.dart';
import 'package:howpa_nurse/features/home/presentation/screens/nurse_dashboard_screen.dart';
import 'package:howpa_nurse/features/visits/presentation/screens/visits_screen.dart';
import 'package:howpa_nurse/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:howpa_nurse/features/profile/presentation/screens/profile_screen.dart';

class BottomNavScreen extends StatelessWidget {
  const BottomNavScreen({super.key});

  static const List<Widget> _screens = [
    NurseDashboardScreen(),
    VisitsScreen(),
    NotificationsScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => BottomNavBarCubit(),
      child: BlocBuilder<BottomNavBarCubit, BottomNavBarState>(
        builder: (context, state) {
          return Scaffold(
            body: IndexedStack(
              index: state.selectedIndex,
              children: _screens,
            ),
            bottomNavigationBar: CustomBottomBar(
              currentIndex: state.selectedIndex,
              onTap: (index) => context.read<BottomNavBarCubit>().changeTab(index),
            ),
          );
        },
      ),
    );
  }
}

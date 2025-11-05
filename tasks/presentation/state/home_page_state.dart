import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomePageState {
  final String searchQuery;
  final int selectedIndex;

  const HomePageState({
    this.searchQuery = '',
    this.selectedIndex = 0,
  });

  HomePageState copyWith({
    String? searchQuery,
    int? selectedIndex,
  }) {
    return HomePageState(
      searchQuery: searchQuery ?? this.searchQuery,
      selectedIndex: selectedIndex ?? this.selectedIndex,
    );
  }
}

class HomePageNotifier extends StateNotifier<HomePageState> {
  HomePageNotifier() : super(const HomePageState());

  void updateSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void updateSelectedIndex(int index) {
    state = state.copyWith(selectedIndex: index);
  }
}

final homePageNotifierProvider =
    StateNotifierProvider.autoDispose<HomePageNotifier, HomePageState>(
  (ref) => HomePageNotifier(),
);
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/restaurant_model.dart';
import '../../../shared/models/menu_item_model.dart';

/// Holds all selections across the 3 steps of the rating flow.
class RatingFlowState {
  final int currentStep;
  final RestaurantModel? selectedRestaurant;
  final MenuItemModel? selectedMenuItem;
  final double score;
  final String comment;
  final bool isLoading;
  final String? errorMessage;

  const RatingFlowState({
    this.currentStep = 0,
    this.selectedRestaurant,
    this.selectedMenuItem,
    this.score = 0,
    this.comment = '',
    this.isLoading = false,
    this.errorMessage,
  });

  RatingFlowState copyWith({
    int? currentStep,
    RestaurantModel? selectedRestaurant,
    MenuItemModel? selectedMenuItem,
    double? score,
    String? comment,
    bool? isLoading,
    String? errorMessage,
  }) {
    return RatingFlowState(
      currentStep: currentStep ?? this.currentStep,
      selectedRestaurant: selectedRestaurant ?? this.selectedRestaurant,
      selectedMenuItem: selectedMenuItem ?? this.selectedMenuItem,
      score: score ?? this.score,
      comment: comment ?? this.comment,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class RatingFlowNotifier extends StateNotifier<RatingFlowState> {
  RatingFlowNotifier() : super(const RatingFlowState());

  void selectRestaurant(RestaurantModel restaurant) {
    state = state.copyWith(
      selectedRestaurant: restaurant,
      currentStep: 1,
    );
  }

  void selectMenuItem(MenuItemModel item) {
    state = state.copyWith(
      selectedMenuItem: item,
      currentStep: 2,
    );
  }

  void updateScore(double newScore) {
    state = state.copyWith(score: newScore);
  }

  void updateComment(String newComment) {
    state = state.copyWith(comment: newComment);
  }

  void goBack() {
    if (state.currentStep > 0) {
      state = state.copyWith(currentStep: state.currentStep - 1);
    }
  }

  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  void showError(String message) {
    state = state.copyWith(errorMessage: message, isLoading: false);
  }

  void jumpToRateItem(RestaurantModel restaurant, MenuItemModel item) {
    state = RatingFlowState(
      currentStep: 2,
      selectedRestaurant: restaurant,
      selectedMenuItem: item,
    );
  }

  void reset() {
    state = const RatingFlowState();
  }
}

final ratingFlowProvider =
    StateNotifierProvider<RatingFlowNotifier, RatingFlowState>(
  (ref) => RatingFlowNotifier(),
);

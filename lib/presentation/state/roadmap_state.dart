// Presentation layer (State): State of the roadmap's topic tree.

import 'package:signals_flutter/signals_flutter.dart';

import '../../domain/entities/topic_node.dart';

/// Tree of the user's track, already nested and with the sequential state set
/// by GetRoadmapTreeUseCase.
final roadmapTree = signal<List<TopicNode>>(<TopicNode>[]);

/// Loading the tree.
final roadmapLoading = signal<bool>(false);

/// Error message. `null` if there is none.
final roadmapError = signal<String?>(null);

/// It has been loaded at least once already.
///
/// It tells "I have not loaded yet" from "I loaded and there is nothing":
/// without it, the empty state would flash on the first paint.
final roadmapLoaded = signal<bool>(false);

/// All the leaf topics of the tree, in order.
///
/// Progress is counted over the leaves and not over every node: a module with
/// three topics inside is not a fourth thing to complete, it is the set of
/// those three. Counting it would double the denominator.
final roadmapLeaves = computed<List<TopicNode>>(() {
  return [
    for (final root in roadmapTree.value)
      ...root.flattened.where((node) => node.isLeaf),
  ];
});

/// How many leaves are completed.
final roadmapCompletedCount =
    computed(() => roadmapLeaves.value.where((n) => n.isCompleted).length);

/// Progress fraction, from 0 to 1. Zero if the track has no topics yet.
final roadmapProgress = computed(() {
  final total = roadmapLeaves.value.length;
  if (total == 0) return 0.0;
  return roadmapCompletedCount.value / total;
});

/// The track has no topics loaded.
///
/// It is the normal case today for backend and infrastructure: the curriculum
/// is an open decision of Module 2.
final roadmapIsEmpty = computed(
  () => roadmapLoaded.value && roadmapTree.value.isEmpty,
);

/// Leaves the roadmap as if it had just been opened. It is called on sign-out.
void resetRoadmap() {
  roadmapTree.value = <TopicNode>[];
  roadmapLoading.value = false;
  roadmapError.value = null;
  roadmapLoaded.value = false;
}

extends RefCounted
class_name MazePointTypes

enum SplashMode {
	NONE,
	TITLE,
	PAUSED,
	LEVEL_COMPLETE,
	LEVEL_FAILED,
	RUN_COMPLETE,
}

enum GoalResolveOutcome {
	NONE,
	SUCCESS,
	FAILURE,
}

enum TransitionAction {
	NONE,
	START_RUN,
	NEXT_LEVEL,
}

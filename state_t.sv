package state_t;
	typedef enum logic [4:0] {
		 RESET, // 0
		 IDLE,  // 1
		 INIT,  // 2
		 LOAD_END, // 3
		 BOUND_CHECK1, // 4
		 BOUND_CHECK2, // 5
		 BOUND_CHECK3, // 6
		 BOUND_CHECK4, // 7
		 VISIT_NODES1, // 8
		 VISIT_NODES2, // 9
		 VISIT_NODES3, // 10
		 VISIT_NODES4, // 11
		 CHECK_NEIGHBORS, // 12
		 DONE_BFS, // 13
		 LOAD_PREV, // 14
		 TRACE_PATH, // 15
		 FINISH // 16
	} state_t;
endpackage
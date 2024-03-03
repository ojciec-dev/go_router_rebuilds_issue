# go_router_test

This app demonstrates that using GoRouter(v13.2.0) with non-const widgets causes [build] method being called on
Widgets that are no longer visible. However, the same transitions but using standard Navigator API does not cause
unnecessary rebuilds.

There are 4 nested pages: home > pageA > pageB > pageC > pageD.

Steps to reproduce the issue:
1. Set [_useGoRouter] to true and run the app
2. Navigate from Home to pageD (via pageA, pageB and pageC)
3. Observe the logs/snackbar and notice that [build] method of pageA and pageB gets called when we navigate to pageC
    and pageD. At this point pageA and pageB are not visible, but still their [build] method is called.

4. Change [_useGoRouter] to false and restart the app
5. Again navigate from Home to pageD (via pageA, pageB and pageC)
6. Notice that this time pageA and pageB are not unneccessarily rebuilt

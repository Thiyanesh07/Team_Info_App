# Team Info App - Manual Runtime QA Checklist

## Scope
This checklist is for manual runtime verification only.
Use it to validate each screen feature-by-feature with expected behavior and pass/fail tracking.

## Execution Metadata
- Build under test:
- Commit hash:
- Tester name:
- Test date:
- Device/OS:
- App variant: debug/release
- Network profile: Wi-Fi / 4G / offline simulation

## Result Codes
- P = Pass
- F = Fail
- B = Blocked (cannot test due to dependency)
- N/A = Not applicable for role/device

## Bug Severity Guide
- Critical: crash, data loss, auth bypass, broken core flow
- High: major feature unusable, wrong data shown/saved
- Medium: feature works partially with clear impact
- Low: UI polish issue, minor edge-case behavior

---

## Master Test Case Template
Use one row per test case execution.

| Test ID | Screen/Module | Scenario | Steps | Expected Result | Actual Result | Status (P/F/B/N/A) | Severity (if F) | Bug ID/Link | Notes |
|---|---|---|---|---|---|---|---|---|---|
| EX-001 | Example | Example scenario | 1) Open app 2) Tap X | Y should happen |  |  |  |  |  |

---

## Pre-Run Setup Checklist

| Item | Expected Result | Status | Notes |
|---|---|---|---|
| App installs successfully | App launches to login/home |  |  |
| Backend reachable | Health APIs return success |  |  |
| DB reachable | Data reads/writes work |  |  |
| Push permission flow available | User can allow notifications |  |  |
| Test users prepared | MEMBER, LEADER, ADMIN accounts ready |  |  |
| Seed data available | At least 1 project/task/report/chat history |  |  |

---

## 1) Authentication and Session

| Test ID | Scenario | Steps | Expected Result | Actual | Status | Severity | Bug ID | Notes |
|---|---|---|---|---|---|---|---|---|
| AUTH-001 | Google login success | Login with valid account | User enters app shell |  |  |  |  |  |
| AUTH-002 | Login cancel handling | Start login then cancel | User remains unauthenticated, no crash |  |  |  |  |  |
| AUTH-003 | Session restore | Relaunch app after login | User remains logged in |  |  |  |  |  |
| AUTH-004 | Logout | Logout from profile/settings | User returns to login screen |  |  |  |  |  |
| AUTH-005 | FCM token sync post-login | Login and inspect backend user fcmToken | Token is saved/updated on backend |  |  |  |  |  |

---

## 2) App Shell and Navigation

| Test ID | Scenario | Steps | Expected Result | Actual | Status | Severity | Bug ID | Notes |
|---|---|---|---|---|---|---|---|---|
| NAV-001 | Bottom tabs switch | Tap each tab: Home, Projects, Chat, Tasks, Profile | Correct screen shown each time |  |  |  |  |  |
| NAV-002 | Back navigation behavior | Open nested page then back | Returns to previous screen, no freeze |  |  |  |  |  |
| NAV-003 | Offline banner | Disable internet while in app | Offline indicator appears and recovers after reconnect |  |  |  |  |  |

---

## 3) Chat - Chat List Screen

| Test ID | Scenario | Steps | Expected Result | Actual | Status | Severity | Bug ID | Notes |
|---|---|---|---|---|---|---|---|---|
| CHATL-001 | Open Team Chat card | Tap Team Chat card | Team chat screen opens |  |  |  |  |  |
| CHATL-002 | Open personal conversation | Tap a personal chat row | Correct conversation opens |  |  |  |  |  |
| CHATL-003 | Start new chat | Add icon -> pick user | Conversation opens/created once |  |  |  |  |  |
| CHATL-004 | Unread badge display | Receive message while not in that conversation | Unread count badge increments for that conversation |  |  |  |  |  |
| CHATL-005 | Unread clear after read | Open conversation and read messages, return | Unread badge clears/reduces correctly |  |  |  |  |  |

---

## 4) Chat - Team Chat Screen

| Test ID | Scenario | Steps | Expected Result | Actual | Status | Severity | Bug ID | Notes |
|---|---|---|---|---|---|---|---|---|
| CHAT-T-001 | Send text | Enter text and send | Message appears once with correct sender and time |  |  |  |  |  |
| CHAT-T-002 | Send image | Attach from camera/gallery | Image bubble appears and loads |  |  |  |  |  |
| CHAT-T-003 | Send document | Attach document | File bubble appears with open/download actions |  |  |  |  |  |
| CHAT-T-004 | Send voice | Long press mic/send voice flow | Voice bubble appears and plays |  |  |  |  |  |
| CHAT-T-005 | Reply by swipe | Swipe a message then send | Reply context shown, sent message linked to replyToId |  |  |  |  |  |
| CHAT-T-006 | Reactions | Long press -> choose emoji | Reaction count updates in real-time |  |  |  |  |  |
| CHAT-T-007 | Tick state | Send from user A and read from user B | Sender sees single/double/blue tick progression as designed |  |  |  |  |  |
| CHAT-T-008 | Timestamp correctness | Compare displayed time to IST | Message times shown in IST consistently |  |  |  |  |  |
| CHAT-T-009 | Sender identity correctness | Send from admin and member accounts | Messages align to correct sender and side |  |  |  |  |  |

---

## 5) Chat - Personal Chat Screen

| Test ID | Scenario | Steps | Expected Result | Actual | Status | Severity | Bug ID | Notes |
|---|---|---|---|---|---|---|---|---|
| CHAT-P-001 | Open specific conversation | Launch from chat list/notification | Correct conversationId opens |  |  |  |  |  |
| CHAT-P-002 | Text message flow | Send/receive text | Message appears once for both users |  |  |  |  |  |
| CHAT-P-003 | Attachment flow | Send image/document/voice | Correct bubble type appears and opens |  |  |  |  |  |
| CHAT-P-004 | Read receipts | Receiver opens chat | Sender read indicator updates |  |  |  |  |  |
| CHAT-P-005 | Swipe reply | Swipe and send reply | Reply context works and can cancel |  |  |  |  |  |
| CHAT-P-006 | Typing indicator | Type as user A while user B watches | Typing status appears/disappears correctly |  |  |  |  |  |

---

## 6) Tasks Module

| Test ID | Scenario | Steps | Expected Result | Actual | Status | Severity | Bug ID | Notes |
|---|---|---|---|---|---|---|---|---|
| TASK-001 | Member sees My Tasks | Login as member | Assigned tasks visible |  |  |  |  |  |
| TASK-002 | Leader tabs | Login as leader/admin | My Tasks and Assigned by Me tabs visible |  |  |  |  |  |
| TASK-003 | Create task | Create/assign task to user | Task appears for assignee and creator |  |  |  |  |  |
| TASK-004 | Update status | Assignee updates status | Status updates and persists |  |  |  |  |  |
| TASK-005 | Add report | Assignee submits report text | Report appears in task detail |  |  |  |  |  |
| TASK-006 | Delete task authorization | Non-owner tries delete | Access denied or action hidden |  |  |  |  |  |
| TASK-007 | Notification deep link | Tap task push | Opens exact Task Detail screen |  |  |  |  |  |

---

## 7) Reports Module

| Test ID | Scenario | Steps | Expected Result | Actual | Status | Severity | Bug ID | Notes |
|---|---|---|---|---|---|---|---|---|
| REP-001 | Leader creates request | Create report request with audience options | Request saved and visible in Manage list |  |  |  |  |  |
| REP-002 | Member assigned list | Login as targeted member | Request appears in Assigned to Me |  |  |  |  |  |
| REP-003 | Submit report with file | Upload allowed file and submit | Submission saved with status PENDING |  |  |  |  |  |
| REP-004 | Update submission | Edit notes/file and resubmit | Submission updates correctly |  |  |  |  |  |
| REP-005 | Review submission | Leader marks COMPLETED/REDO | Status updates and reflects for member |  |  |  |  |  |
| REP-006 | Request counts | Check submissions count in manage list | Count matches actual submissions |  |  |  |  |  |
| REP-007 | In-app file preview | Open submitted file preview | Opens in-app, not external browser unexpectedly |  |  |  |  |  |
| REP-008 | Notification deep link | Tap new submission task push | Opens exact request submission/review target |  |  |  |  |  |

---

## 8) Projects Module

| Test ID | Scenario | Steps | Expected Result | Actual | Status | Severity | Bug ID | Notes |
|---|---|---|---|---|---|---|---|---|
| PROJ-001 | Personal project list/create | Add personal project | Appears in list with details |  |  |  |  |  |
| PROJ-002 | Team project create | Leader creates team project | Project appears for relevant users |  |  |  |  |  |
| PROJ-003 | Assign members | Update project members | Membership updates correctly |  |  |  |  |  |
| PROJ-004 | Open project detail | Tap team project card | Correct project detail opens |  |  |  |  |  |
| PROJ-005 | Add progress update | Member/captain posts update | Update appears in activity list |  |  |  |  |  |
| PROJ-006 | Notification deep link | Tap project push | Opens exact project detail by projectId |  |  |  |  |  |

---

## 9) Profile and Admin Flows

| Test ID | Scenario | Steps | Expected Result | Actual | Status | Severity | Bug ID | Notes |
|---|---|---|---|---|---|---|---|---|
| PROF-001 | Edit profile fields | Update editable profile fields | Values persist after refresh |  |  |  |  |  |
| PROF-002 | Self AP/RP update path | Edit own points where allowed | Uses proper endpoint and updates user model |  |  |  |  |  |
| PROF-003 | Certification upload | Upload cert proof and open preview | File upload and in-app actions work |  |  |  |  |  |
| PROF-004 | Portal sync normal flow | Perform portal sync | Sync completes and points update |  |  |  |  |  |
| PROF-005 | Portal sync fallback flow | Use manual fallback inputs | Backend computes totals/contribution correctly |  |  |  |  |  |
| ADMIN-001 | Dashboard loads | Open admin dashboard | Metrics and lists load without crash |  |  |  |  |  |
| ADMIN-002 | Reward sync actions | Run admin sync endpoints | Sync response succeeds and data updates |  |  |  |  |  |

---

## 10) Push Notifications and Deep Linking

| Test ID | Scenario | Steps | Expected Result | Actual | Status | Severity | Bug ID | Notes |
|---|---|---|---|---|---|---|---|---|
| PUSH-001 | Permission prompt | First launch on fresh install | Prompt appears and user choice handled |  |  |  |  |  |
| PUSH-002 | FCM token persistence | Login and inspect backend user record | fcmToken saved/updated |  |  |  |  |  |
| PUSH-003 | Team chat push open | Receive team chat push and tap | Opens Team Chat |  |  |  |  |  |
| PUSH-004 | Personal chat push open | Receive personal push and tap | Opens exact conversation |  |  |  |  |  |
| PUSH-005 | Task push open | Receive task push and tap | Opens exact Task Detail |  |  |  |  |  |
| PUSH-006 | Report push open | Receive report push and tap | Opens exact submission/review target |  |  |  |  |  |
| PUSH-007 | Project push open | Receive project push and tap | Opens exact Project Detail |  |  |  |  |  |
| PUSH-008 | Rapid duplicate tap guard | Tap same push repeatedly quickly | Only one navigation occurs |  |  |  |  |  |
| PUSH-009 | Already-open smart dedupe | Stay on target screen then tap same target push | No duplicate route pushed |  |  |  |  |  |
| PUSH-010 | Cold start push tap | Force stop app then tap push | Correct destination opens after app start |  |  |  |  |  |

---

## 11) Negative and Resilience Cases

| Test ID | Scenario | Steps | Expected Result | Actual | Status | Severity | Bug ID | Notes |
|---|---|---|---|---|---|---|---|---|
| NEG-001 | API timeout during load | Simulate slow network | Graceful loader/error snackbar, no crash |  |  |  |  |  |
| NEG-002 | Unauthorized route access | Attempt restricted action as member | Action blocked with clear feedback |  |  |  |  |  |
| NEG-003 | File upload failure | Disable internet mid-upload | User gets actionable error, can retry |  |  |  |  |  |
| NEG-004 | Duplicate send prevention | Tap send rapidly | No duplicated duplicate messages beyond designed behavior |  |  |  |  |  |
| NEG-005 | App resume from background | Background app during active chat/task/report screen | Returns without broken state |  |  |  |  |  |

---

## 12) Regression Sign-Off Matrix

| Module | Pass % | Critical Bugs | High Bugs | Medium Bugs | Low Bugs | Sign-Off |
|---|---:|---:|---:|---:|---:|---|
| Authentication |  |  |  |  |  |  |
| Navigation/Shell |  |  |  |  |  |  |
| Chat |  |  |  |  |  |  |
| Tasks |  |  |  |  |  |  |
| Reports |  |  |  |  |  |  |
| Projects |  |  |  |  |  |  |
| Profile/Admin |  |  |  |  |  |  |
| Push/Deep Link |  |  |  |  |  |  |

---

## Bug Log (Detailed)

| Bug ID | Module | Title | Steps to Reproduce | Expected | Actual | Severity | Environment | Status | Owner |
|---|---|---|---|---|---|---|---|---|---|
| BUG-001 |  |  |  |  |  |  |  | Open |  |

---

## Final QA Summary
- Total test cases executed:
- Passed:
- Failed:
- Blocked:
- Release recommendation: GO / NO-GO
- QA Lead sign-off:

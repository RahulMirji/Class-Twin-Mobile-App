# ClassTwin — PRD Addendum: Hybrid Classroom Streaming
### Extends: Student Mobile App PRD v2.0
### Version: 1.0 | April 2026
### Status: Engineering Review Draft

---

## Changelog / Why This Addendum Exists

The v2.0 PRD assumed all students are physically present in the classroom. This addendum introduces **hybrid classroom support** — remote students join the same session via live stream while in-room students retain their existing experience untouched.

This is not a minor feature. Streaming changes:
- The student identity model (new `mode` field: in-room vs remote)
- The infrastructure stack (WebRTC layer on top of Supabase)
- 4 net-new screens for remote students
- 2 overlapping screens that gain new affordances for remote students
- The Supabase schema (2 new tables, 2 altered tables)
- Battery/performance targets (relaxed for remote, preserved for in-room)
- The teacher app (out of scope here — flagged for the Teacher PRD)

---

## 1. Product Decision: Two Student Modes

From this version forward, a student is either:

| Mode | Definition | Primary Device Use | Stream |
|---|---|---|---|
| `in_room` | Physically present in the classroom | Glanceable signal input | Optional / off by default |
| `remote` | Joining from outside the classroom | Primary learning surface | Always on |

The mode is **chosen at join time** on the JoinScreen and stored with the student record. It cannot be changed mid-session.

Remote students get the full existing response experience (QuestionScreen, WaitingScreen, etc.) — the stream is a layer *on top of* that flow, not a replacement for it.

---

## 2. Streaming Stack Decision: LiveKit

### Why LiveKit

| Option | Verdict | Reason |
|---|---|---|
| LiveKit | ✅ Chosen | Open-source SFU, excellent Flutter SDK (`livekit_client`), supports simulcast, screen share, and data channels. Self-hostable or managed cloud. |
| Agora | ❌ | Proprietary, expensive at scale, less Flutter-native |
| Daily.co | ❌ | No native Flutter SDK — WebView only, poor mobile UX |
| Jitsi | ❌ | No production-grade Flutter SDK, difficult to customize |
| Raw WebRTC | ❌ | `flutter_webrtc` is low-level, no SFU — doesn't scale past ~8 peers |

### LiveKit Architecture for ClassTwin

```
Teacher Laptop
  └── LiveKit Publisher (Web SDK or Electron)
        ├── Video track: webcam feed
        └── Screen track: slides / desktop share

LiveKit SFU (Cloud)
  └── Session Room: one room per ClassTwin session
        └── Selective forwarding to all subscribers

Student Phones (Flutter)
  └── LiveKit Subscriber (livekit_client Flutter SDK)
        ├── Subscribes to video track (teacher face)
        └── Subscribes to screen track (slides)
        
Supabase Realtime (unchanged)
  └── Still handles: questions, responses, session state, presence
  └── NEW: hand raises, chat messages (via Realtime broadcast)

LiveKit Data Channels
  └── NOT used for ClassTwin — Supabase handles all data messaging
      (Keeps the data layer clean and consistent)
```

### LiveKit Room Lifecycle

```
Session created → LiveKit room created (server-side, teacher app)
Teacher starts stream → LiveKit room becomes active
Student joins as remote → Flutter app subscribes to room
Session ends → LiveKit room destroyed
```

LiveKit room name = ClassTwin `session_id` (UUID). One-to-one mapping. No separate room ID to manage.

---

## 3. Supabase Schema Changes

### 3.1 Altered Tables

```sql
-- session_students: add mode column
alter table session_students
  add column mode text not null default 'in_room'
    check (mode in ('in_room', 'remote'));

-- sessions: add streaming columns
alter table sessions
  add column is_streaming     boolean not null default false,
  add column livekit_room_name text,           -- set when teacher starts stream
  add column stream_started_at timestamptz,
  add column chat_enabled     boolean not null default true,
  add column hand_raise_enabled boolean not null default true;
```

### 3.2 New Tables

```sql
-- Chat messages (per session)
create table chat_messages (
  id            uuid primary key default gen_random_uuid(),
  session_id    uuid not null references sessions(id) on delete cascade,
  student_id    uuid not null references session_students(id) on delete cascade,
  student_name  text not null,                -- denormalized for display speed
  message_text  text not null,
  is_anonymous  boolean not null default false,
  sent_at       timestamptz not null default now()
);

-- Hand raises (per round — resets each round)
create table hand_raises (
  id            uuid primary key default gen_random_uuid(),
  session_id    uuid not null references sessions(id) on delete cascade,
  student_id    uuid not null references session_students(id) on delete cascade,
  round_number  int not null,
  raised_at     timestamptz not null default now(),
  lowered_at    timestamptz,                  -- null = still raised
  unique (session_id, student_id, round_number)
);
```

### 3.3 New RLS Policies

```sql
-- Chat: students can insert and read messages in their session
create policy "Students can send chat messages"
  on chat_messages for insert
  with check (true);

create policy "Students can read session chat"
  on chat_messages for select
  using (true);

-- Hand raises: students can insert and update their own raises
create policy "Students can raise hand"
  on hand_raises for insert
  with check (true);

create policy "Students can lower hand"
  on hand_raises for update
  using (true);

create policy "Teacher can read hand raises"
  on hand_raises for select
  using (true);
```

### 3.4 Realtime Channels — Extended

```
Existing channel: session:{sessionId}
  Existing events: session:started, session:next_question, session:ended, session:result

New broadcast events on same channel:
  type: chat:message    payload: { studentId, studentName, message, isAnonymous, sentAt }
  type: hand:raised     payload: { studentId, studentName, roundNumber }
  type: hand:lowered    payload: { studentId, roundNumber }
  type: stream:started  payload: { livelkitRoomName, roomToken }
  type: stream:ended    payload: {}
```

---

## 4. LiveKit Flutter Integration

### 4.1 Package

```yaml
dependencies:
  livekit_client: ^2.x     # Flutter LiveKit SDK
```

### 4.2 LiveKit Token Flow

The student never directly authenticates with LiveKit. Tokens are generated server-side via a Supabase Edge Function:

```
Student (Flutter)                  Supabase Edge Function          LiveKit Cloud
  |                                        |                             |
  |-- POST /functions/v1/livekit-token --> |                             |
  |   body: { sessionId, studentId }       |                             |
  |                                        |-- Generate JWT token ------->|
  |                                        |   (participant identity =    |
  |                                        |    studentId, room =         |
  |                                        |    sessionId, subscriber     |
  |                                        |    only — no publish perms)  |
  |<-- { token, wsUrl } ------------------|                             |
  |                                        |                             |
  |-- Connect to LiveKit room ------------>|<----------------------------|
      (subscriber only — cannot publish)
```

```dart
// Supabase Edge Function: /functions/v1/livekit-token
// (TypeScript, deployed to Supabase)
import { AccessToken } from 'livekit-server-sdk';

const token = new AccessToken(LIVEKIT_API_KEY, LIVEKIT_API_SECRET, {
  identity: studentId,
});
token.addGrant({
  roomJoin: true,
  room: sessionId,
  canPublish: false,       // students never publish
  canSubscribe: true,
  canPublishData: false,   // data goes through Supabase, not LiveKit
});
return { token: token.toJwt(), wsUrl: LIVEKIT_WS_URL };
```

### 4.3 Stream Service

```dart
class StreamService {
  Room? _room;
  VideoTrack? _teacherCameraTrack;
  VideoTrack? _teacherScreenTrack;

  Stream<VideoTrack?> get cameraTrack => _cameraTrackController.stream;
  Stream<VideoTrack?> get screenTrack => _screenTrackController.stream;

  final _cameraTrackController = StreamController<VideoTrack?>.broadcast();
  final _screenTrackController  = StreamController<VideoTrack?>.broadcast();

  Future<void> connect({ required String wsUrl, required String token }) async {
    _room = Room();

    _room!.on<TrackSubscribedEvent>((event) {
      if (event.track is VideoTrack) {
        final video = event.track as VideoTrack;
        // LiveKit source: camera vs screen share
        if (event.publication.source == TrackSource.screenShareVideo) {
          _screenTrackController.add(video);
        } else {
          _cameraTrackController.add(video);
        }
      }
    });

    _room!.on<TrackUnsubscribedEvent>((event) {
      if (event.publication.source == TrackSource.screenShareVideo) {
        _screenTrackController.add(null);
      } else {
        _cameraTrackController.add(null);
      }
    });

    await _room!.connect(wsUrl, token);
  }

  Future<void> disconnect() async {
    await _room?.disconnect();
    _room = null;
  }
}
```

---

## 5. Updated State Model

### 5.1 New Session States (Remote Only)

The existing sealed `SessionState` class gains two new states:

```dart
// Student is remote and stream is live
class SessionStreaming extends SessionState {
  final Session session;
  final Question? currentQuestion;    // null between rounds
  final int? roundNumber;
  final StudentResponse? submittedResponse;
  final bool isScreenShareActive;     // teacher sharing slides
  final StreamLayout layout;          // enum: pipCamera | fullScreen | sideBySide
  const SessionStreaming({
    required this.session,
    this.currentQuestion,
    this.roundNumber,
    this.submittedResponse,
    this.isScreenShareActive = false,
    this.layout = StreamLayout.fullScreen,
  });
}

// Session is live but stream hasn't started yet (teacher hasn't hit broadcast)
class SessionStreamPending extends SessionState {
  final Session session;
  const SessionStreamPending(this.session);
}

enum StreamLayout { pipCamera, fullScreen, sideBySide }
```

### 5.2 Mode-Aware Providers

```dart
// New provider: student mode
final studentModeProvider = StateProvider<StudentMode>((ref) => StudentMode.inRoom);

enum StudentMode { inRoom, remote }

// Stream service provider (lazy — only initializes for remote students)
final streamServiceProvider = Provider<StreamService>((ref) {
  final service = StreamService();
  ref.onDispose(() => service.disconnect());
  return service;
});
```

---

## 6. Updated Screen Map

### Existing Screens — Behavior by Mode

| Screen | In-Room Behavior | Remote Behavior |
|---|---|---|
| JoinScreen | Unchanged | Gains mode selector (Step 2 of join) |
| LobbyScreen | Unchanged | Shows "Stream starting soon…" if `is_streaming=false` |
| QuestionScreen | Unchanged | Gains stream overlay (mini PiP camera, top-right) |
| WaitingScreen | Unchanged | Gains chat panel access + hand raise |
| SessionEndScreen | Unchanged | Unchanged |

### New Screens (Remote Students Only)

| Screen | Name | Route | Description |
|---|---|---|---|
| `StreamScreen` | Live Stream | `/session/:id/stream` | Full-screen stream with response overlay |
| `ChatPanel` | Chat | `/session/:id/chat` | Bottom sheet chat drawer |
| `HandRaiseScreen` | Hand Raise | (modal overlay) | Confirm + lower hand |
| `StreamEndedScreen` | Stream Ended | `/session/:id/stream-ended` | Teacher ended stream mid-session |

---

## 7. Screen-by-Screen Specification (New + Modified)

---

### 7.1 JoinScreen — Modified (Mode Selection)

The join flow for remote students gains a **Step 2**: mode selector, shown only if `session.is_streaming = true` OR `session.hand_raise_enabled = true` (i.e. teacher has enabled hybrid).

If neither flag is true, mode defaults to `in_room` and the step is skipped entirely.

```
Step 1 (unchanged): Name entry
Step 2 (new, conditional): Mode selector

Step 2 layout:
  [Back chevron] ["How are you joining?"]
  [40px spacer]
  [Mode card A: "I'm in the classroom"]
    Icon: MapPin (Phosphor)
    Sub: "Use your phone to respond to questions"
    Height: 80px — same card-cta component from HomeScreen
  [12px gap]
  [Mode card B: "I'm joining remotely"]
    Icon: Monitor (Phosphor)
    Sub: "Watch the live stream + respond to questions"
    Badge: "Requires good WiFi" — amber chip, top-right of card
  [Auto-spacer]
  [Primary Button "Continue"]

Selection behavior:
  - Card highlights with border-strong on tap (same as OTP box focus)
  - Button stays disabled until one mode is selected
  - Mode stored in Hive + sent with session_students INSERT
```

---

### 7.2 LobbyScreen — Modified (Remote)

Remote students see a different waiting state if stream hasn't started:

```
[StreamPending state — replaces hourglass illustration]
  Icon: Broadcast outline SVG (48px, text-tertiary)
  Title: "Stream starting soon"
  Sub: "Your teacher will go live shortly"
  
  [Session info card — bg-surface, border-subtle, radius-lg]
    Topic / Round count / Mode (Remote)

[Once stream:started event arrives via Realtime]
  → Navigate to StreamScreen
  → Animate: fade out lobby → fade in stream (400ms)
```

---

### 7.3 StreamScreen ⭐⭐ (New Core Screen — Remote)

This is the primary screen for remote students. It must do two things simultaneously:
1. Show the live class
2. Accept comprehension responses when questions arrive

```
Route: /session/:id/stream
Navigation: No back button (in-session — use Leave button)

LAYOUT — Default state (no active question):
  ┌─────────────────────────────────┐
  │ [Status bar]                    │
  │ ┌─────────────────────────────┐ │  ← Screen share track (flex: 1)
  │ │                             │ │    VideoView widget (fit: contain)
  │ │   Teacher's slides / screen │ │    bg: #000000 (only place in app)
  │ │                             │ │
  │ │  [PiP: teacher camera]      │ │  ← Picture-in-picture, 100×140px
  │ │   top-right, 12px inset     │ │    border-radius: 10px
  │ │   draggable to any corner   │ │    border: 1.5px solid rgba(255,255,255,0.2)
  │ └─────────────────────────────┘ │
  │ ┌─────────────────────────────┐ │  ← Bottom control bar (bg: --bg-base)
  │ │ [🙋 Raise Hand] [💬 Chat]  │ │    Height: 64px + safe area
  │ │                    [Leave]  │ │    border-top: border-subtle
  │ └─────────────────────────────┘ │
  └─────────────────────────────────┘

LAYOUT — Camera only (no screen share):
  ┌─────────────────────────────────┐
  │ [Status bar]                    │
  │ ┌─────────────────────────────┐ │  ← Teacher camera (flex:1, fit: cover)
  │ │                             │ │    Centered, fills screen
  │ │    [Teacher camera feed]    │ │
  │ │                             │ │
  │ └─────────────────────────────┘ │
  │ [Bottom control bar]            │
  └─────────────────────────────────┘

LAYOUT — Active question (question arrives via Realtime):
  Screen share / camera stays visible (dims to 60% opacity)
  Response panel slides up from bottom (spring animation, 320ms):

  ┌─────────────────────────────────┐
  │ [Stream — dimmed to 60%]        │
  │                                 │
  │                                 │
  │ ┌─────────────────────────────┐ │  ← Response panel (bg-base, top radius 24px)
  │ │ [Timer bar — 3px, full]     │ │    Height: auto (~280px)
  │ │ [Question text — DM Serif]  │ │
  │ │ [Got It button]             │ │
  │ │ [Somewhat button]           │ │
  │ │ [Lost button]               │ │
  │ │ [Add detail link]           │ │
  │ └─────────────────────────────┘ │
  └─────────────────────────────────┘

  After response: panel shrinks to 80px showing only selected response chip
  Stream returns to full opacity (300ms ease)
  Undo toast appears above the mini panel

LAYOUT — Screen share + camera toggle:
  Double-tap PiP camera → swap: camera goes fullscreen, screen share → PiP
  Double-tap again → revert
  PiP is draggable to any corner (long-press → drag)
```

**Stream quality adaptive logic:**

```dart
// Degrade gracefully on poor connection
// LiveKit handles simulcast — app requests quality tier based on bandwidth
enum StreamQuality { high, medium, low, audioOnly }

class StreamQualityAdapter {
  StreamQuality currentQuality = StreamQuality.high;

  void onNetworkDegraded() {
    switch (currentQuality) {
      case StreamQuality.high:   currentQuality = StreamQuality.medium; break;
      case StreamQuality.medium: currentQuality = StreamQuality.low;    break;
      case StreamQuality.low:    currentQuality = StreamQuality.audioOnly; break;
      case StreamQuality.audioOnly: break; // already minimum
    }
    _applyQuality();
    _showQualityBanner(); // amber banner: "Switching to lower quality"
  }

  void _applyQuality() {
    // LiveKit: set preferred quality on video track subscription
    room.localParticipant?.setTrackSubscriptionPermissions(
      allParticipantsAllowed: true,
      trackPermissions: [/* quality config */],
    );
  }
}
```

**Stream ended mid-session:**

```dart
// Teacher closes stream but session is still active (questions may continue)
// Realtime: stream:ended event
// → Disconnect LiveKit room
// → Navigate to StreamEndedScreen (NOT SessionEndScreen)
// → Student can continue answering questions if session is still active
```

---

### 7.4 ChatPanel (New — Bottom Sheet)

Triggered by the Chat button in the StreamScreen bottom bar. Also accessible from WaitingScreen for remote students.

```
Presentation: Bottom sheet — slides up, covers ~70% of screen
Background: --bg-base
Handle: 4px × 36px pill, --bg-overlay, centered, 12px from top

Layout:
  [Handle]
  [12px spacer]
  [Header row]
    ["Class Chat" — DM Sans 500, 16px, text-primary]
    [Toggle: "Anonymous" — small switch, right-aligned]
    [  Label: DM Sans 400, 13px, text-secondary]
  [1px divider border-subtle]
  
  [Message list — flex:1, scrollable]
    Each message:
      [Name — DM Sans 500, 13px, text-primary OR "Anonymous" text-tertiary]
      [4px gap]
      [Message text — DM Sans 400, 14px, text-secondary]
      [4px gap]
      [Timestamp — DM Sans 400, 11px, text-tertiary]
      [12px gap between messages]
    Own messages: right-aligned, bg-surface bubble
    Others: left-aligned, no bubble (editorial style — not SMS-style)
    
  [Input area — border-top border-subtle, padding 12px 16px]
    [Text field, height 44px, bg-surface, border-subtle, radius-full]
      [Placeholder: "Ask a question..."]
      [Send button: ink circle 32px, right side of field]
        [Arrow icon 16px, accent-ink-fg]

Anonymous mode behavior:
  Toggle ON  → name shows as "Anonymous" in sent messages
  Toggle OFF → name shows as student's chosen name
  Toggle state persists in SharedPreferences per session
  
Message delivery:
  1. Optimistic insert → show immediately in own list (pending state)
  2. POST to Supabase chat_messages → broadcast via Realtime
  3. All other students receive via Realtime broadcast
  4. If POST fails → mark message with amber ⚠ indicator
  
Rate limiting (client-side):
  Max 1 message per 3 seconds — button disabled + cooldown indicator
```

---

### 7.5 HandRaiseScreen (New — Modal Overlay)

Triggered by the Raise Hand button in StreamScreen bottom bar.

```
Presentation: Modal overlay — NOT a full screen navigation
  Background: rgba(0,0,0,0.5) behind sheet (full-screen faux viewport)
  Sheet: bg-base, radius-xl (top corners only), centered vertically

Layout (hand NOT raised):
  [Illustration: hand outline SVG, 56px, text-tertiary]
  [16px gap]
  ["Raise your hand" — DM Sans 500, 18px, text-primary, centered]
  [8px gap]
  ["Your teacher will see this on their dashboard" — DM Sans 400, 13px, text-secondary, centered]
  [28px gap]
  [Primary button: "Raise Hand" — full-width, --accent-ink]
  [12px gap]
  [Text link: "Cancel" — text-secondary, centered]

Layout (hand IS raised):
  [Illustration: hand filled SVG, 56px, --response-got-it (green)]
  [16px gap]
  ["Your hand is raised" — DM Sans 500, 18px, text-primary, centered]
  [8px gap]
  ["Waiting for your teacher to respond" — DM Sans 400, 13px, text-secondary, centered]
  [28px gap]
  [Primary button: "Lower Hand" — bg-surface, border-medium, text-primary]
  [12px gap]
  [Text link: "Close" — text-secondary, centered]

Hand raise delivery:
  INSERT to hand_raises table → Supabase broadcasts hand:raised event
  Teacher dashboard receives the event and shows student name
  
Auto-lower:
  When session:next_question arrives → hand is automatically lowered
  (Resets per-round — INSERT new row on next raise)
  
Persistence:
  Hand raise state stored in provider — survives app backgrounding within session
```

---

### 7.6 StreamEndedScreen (New)

Shown when `stream:ended` Realtime event arrives mid-session (stream cut, not session ended).

```
Route: /session/:id/stream-ended
Header: None

Layout:
  [Safe area top + 80px]
  [Broadcast-slash outline icon, 48px, text-tertiary, centered]
  [24px gap]
  ["Stream has ended" — DM Sans 500, 20px, text-primary, centered]
  [12px gap]
  ["Your teacher stopped the broadcast. The session may still be active." 
    — DM Sans 400, 14px, text-secondary, centered, 48px margins]
  [Auto-spacer]
  
  [If session.status = 'active']
    [Info card — bg-surface, border-subtle, radius-lg]
      ["Session is still running — you can still respond to questions"]
      [Icon: CheckCircle, --response-got-it, 16px]
    [20px gap]
    [Primary button: "Continue to Session"]  → WaitingScreen / QuestionScreen

  [If session.status = 'ended']
    [Primary button: "View Summary"] → SessionEndScreen
  
  [Safe area bottom]
```

---

## 8. Updated Performance Targets

The original PRD targets were set for in-room students. Remote students have a different usage pattern (active screen watchers, on WiFi, extended session time).

| Requirement | In-Room Target | Remote Target | Notes |
|---|---|---|---|
| Battery drain per 1hr | < 5% | < 18% | Video decode is CPU-heavy — communicate this to users |
| Memory during session | < 150MB | < 280MB | Video buffers add ~100MB overhead |
| App size (APK) | < 30MB | < 42MB | LiveKit SDK adds ~12MB |
| Stream start latency | N/A | < 3s from connect | LiveKit target (not app-controlled) |
| Video latency (glass-to-glass) | N/A | < 800ms | LiveKit SFU target |
| Chat message delivery | N/A | < 500ms | Via Supabase Realtime |
| Hand raise delivery | N/A | < 300ms | Via Supabase Realtime |
| Cold start → HomeScreen | < 2s | < 2s | Unchanged |
| QR scan → join | < 3s | < 3s | Unchanged |

**Battery warning**: Show a one-time informational banner to remote students after joining:
*"Live streaming uses more battery. Plug in if you can for long sessions."*
— dismiss with tap, never show again (SharedPreferences flag).

---

## 9. New Package Dependencies

```yaml
dependencies:
  # Streaming
  livekit_client: ^2.x          # WebRTC SFU client

  # Already in v2.0 (no changes needed)
  supabase_flutter: ^2.x
  flutter_riverpod: ^2.x
  go_router: ^13.x
  hive_flutter: ^1.x
  flutter_local_notifications: ^17.x
  connectivity_plus: ^6.x
  google_fonts: ^6.x
  flutter_animate: ^4.x
  shimmer: ^3.x
  uuid: ^4.x
  sentry_flutter: ^8.x
```

LiveKit adds one dependency. No other packages are needed — chat and hand raises run through Supabase Realtime, not LiveKit data channels.

---

## 10. Updated Folder Structure

```
lib/
├── features/
│   ├── session/          (unchanged)
│   ├── history/          (unchanged)
│   └── stream/           ← NEW feature module
│       ├── data/
│       │   ├── stream_repository.dart   # LiveKit token fetch + connect
│       │   ├── chat_repository.dart     # Supabase chat CRUD
│       │   └── hand_raise_repository.dart
│       ├── domain/
│       │   ├── models/
│       │   │   ├── chat_message.dart
│       │   │   ├── hand_raise.dart
│       │   │   └── stream_quality.dart
│       │   └── stream_state.dart        # StreamQuality enum, layout enum
│       └── presentation/
│           ├── providers/
│           │   ├── stream_provider.dart
│           │   ├── chat_provider.dart
│           │   └── hand_raise_provider.dart
│           └── screens/
│               ├── stream_screen.dart
│               ├── chat_panel.dart
│               ├── hand_raise_modal.dart
│               └── stream_ended_screen.dart
```

---

## 11. Security Additions

### 11.1 LiveKit Token Scoping

Students receive **subscriber-only** tokens — they can never publish audio, video, or screen share. This is enforced in the Supabase Edge Function that mints the token, not in the Flutter app.

```
Token grants:
  canPublish: false        ← hard-coded, never changes
  canSubscribe: true
  canPublishData: false    ← data goes through Supabase only
  roomJoin: true
  room: sessionId          ← token is scoped to one session room
```

### 11.2 Chat Moderation

No automated moderation in MVP. Teacher can see all messages on their dashboard. Future: Supabase Edge Function hook to scan messages before broadcast.

PII note: chat messages are stored in Supabase and are not ephemeral. Do NOT store messages in Sentry. Add `chat_message_id` to Sentry scope, never `message_text`.

### 11.3 Anonymous Mode

When `is_anonymous = true` on a chat message, the student's name is replaced with "Anonymous" **in the database** — not just in the display layer. The `student_id` is still stored (teacher can see if needed), but the name field is written as "Anonymous" at insert time.

```dart
final displayName = isAnonymous ? 'Anonymous' : studentName;
await supabase.from('chat_messages').insert({
  'session_id': sessionId,
  'student_id': studentId,
  'student_name': displayName,   // 'Anonymous' — not the real name
  'message_text': messageText,
  'is_anonymous': isAnonymous,
});
```

---

## 12. New Analytics Events

```dart
// Extend existing AnalyticsEvent enum
enum AnalyticsEvent {
  // ... existing events ...

  // Stream events
  streamConnected,          // LiveKit room joined
  streamDisconnected,       // LiveKit room left (clean)
  streamDropped,            // LiveKit room lost (unclean)
  streamQualityDegraded,    // Simulcast quality step-down triggered
  streamLayoutChanged,      // PiP swap, fullscreen toggle

  // Interaction events
  chatMessageSent,
  chatMessageSentAnonymous,
  handRaised,
  handLowered,
  handAutoLowered,          // lowered by next_question event

  // Mode events
  joinedAsRemote,
  joinedAsInRoom,
  batteryWarningShown,
}
```

---

## 13. Updated Testing Strategy

### New Unit Tests

```
test/unit/
├── stream_quality_adapter_test.dart   # Quality degradation steps
├── chat_rate_limiter_test.dart        # 1 message / 3s enforcement
├── hand_raise_state_test.dart         # Raise / lower / auto-lower
└── livekit_token_test.dart            # Token scope validation (mock)
```

### New Widget Tests

```
test/widget/
├── stream_screen_test.dart            # Layout states: camera, screen share, PiP swap
├── chat_panel_test.dart               # Message send, anonymous toggle, rate limit
├── hand_raise_modal_test.dart         # Raise, lower, auto-lower on question event
└── stream_ended_screen_test.dart      # Both branches: session active vs ended
```

### New Integration Tests

```
integration_test/
├── hybrid_session_flow_test.dart
│   # 1. Join as remote
│   # 2. Wait in lobby (StreamPending state)
│   # 3. stream:started event received
│   # 4. Navigate to StreamScreen
│   # 5. Question arrives → response panel slides up
│   # 6. Tap response → panel shrinks, stream returns to full opacity
│   # 7. Send chat message
│   # 8. Raise hand
│   # 9. next_question event → hand auto-lowered
│   # 10. session:ended → SessionEndScreen

└── stream_quality_degradation_test.dart
    # 1. Join stream at high quality
    # 2. Simulate network degradation (mock connectivity)
    # 3. Verify quality steps down correctly
    # 4. Verify amber banner shown to student
```

---

## 14. MVP vs Post-MVP (Streaming Features)

| Feature | MVP | Post-MVP |
|---|---|---|
| Live stream view (camera + screen share) | ✅ | — |
| PiP camera overlay | ✅ | — |
| PiP draggable to any corner | ✅ | — |
| Response panel overlay on stream | ✅ | — |
| Chat (named + anonymous) | ✅ | — |
| Hand raise | ✅ | — |
| Adaptive stream quality | ✅ | — |
| Battery warning banner | ✅ | — |
| Stream ended mid-session recovery | ✅ | — |
| Audio-only fallback mode | ✅ | — |
| Chat moderation (teacher can delete messages) | ❌ | ✅ |
| Reactions (👍 🤔 etc.) | ❌ | ✅ |
| Student-to-student chat (vs class-wide) | ❌ | ✅ |
| Stream recording / playback | ❌ | ✅ |
| Closed captions (live transcription) | ❌ | ✅ |
| Multi-camera switching (teacher can switch cameras) | ❌ | ✅ |
| Fullscreen landscape mode | ❌ | ✅ |

---

## 15. Open Questions for Teacher App PRD

This addendum is scoped to the **student app only**. The teacher app must handle:

- Starting / stopping the LiveKit broadcast (from laptop browser or desktop app)
- LiveKit room creation (triggered when session is created or when teacher goes live)
- Seeing hand raises on their dashboard (name + count)
- Moderating chat messages
- Enabling / disabling chat and hand raise per session (`chat_enabled`, `hand_raise_enabled` flags)
- Choosing hybrid mode when creating a session (sets `is_streaming` expectation)

These are **not** student app concerns and must be specced separately.

---

*This addendum is self-contained and directly extends PRD v2.0. All schema changes are additive — no existing tables are modified beyond two `ALTER TABLE` statements. The LiveKit integration is isolated to the new `stream/` feature module and does not touch any existing session, question, or response logic.*
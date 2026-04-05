# Class Twin — Intelligent Digital Twin for Hybrid Classrooms

[![Flutter](https://img.shields.io/badge/Flutter-3.10.7-blue.svg)](https://flutter.dev/)
[![Supabase](https://img.shields.io/badge/Supabase-Backend-green.svg)](https://supabase.com/)
[![LiveKit](https://img.shields.io/badge/LiveKit-Streaming-orange.svg)](https://livekit.io/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

**ClassTwin** is a premium mobile application designed to bridge the gap between in-person and remote learning. It enables "Hybrid Classroom Streaming," where remote students join a live class, view teacher camera/screen feeds, and participate in real-time interactive quizzes as if they were physically present.

---

## ✨ Key Features

### 📡 Hybrid Streaming Experience
- **LiveKit Integration**: High-quality, low-latency video streaming (teacher face + screen share).
- **Picture-in-Picture (PiP)**: Draggable video overlay for seamless navigation during multi-track streams.
- **Adaptive Quality**: Dynamic bitrate adjustment based on network conditions (1080p down to audio-only).

### 📝 Real-Time Interaction
- **Instant Questions**: Students respond to comprehension checks ("Got It," "Somewhat," "Lost") in sync with the live class.
- **Interactive Quizzes**: Multi-question rounds with immediate results and leaderboard updates.
- **Visual Feedback**: Real-time response stats displayed to the teacher dashboard.

### 💬 Engagement Tools
- **Class Chat**: Real-time messaging with **Anonymous Mode** support for sensitive questions.
- **Hand Raising**: Digital hand-raise functionality that instantly alerts the teacher's dashboard.
- **Optimistic UI**: Experience smooth interactions even on fluctuating connections.

### 🎨 "Editorial Serenity" Design
- Developed with a premium, typography-focused aesthetic.
- Clean layouts, vibrant gradients, and micro-animations using `flutter_animate`.
- Supports Light/Dark modes with optimized contrast for long learning sessions.

---

## 🛠️ Tech Stack

- **Core**: [Flutter SDK](https://flutter.dev/) (v3.10.7+)
- **State Management**: [Riverpod](https://riverpod.dev/) (v2.x)
- **Backend & Auth**: [Supabase](https://supabase.com/) (Database, Auth, Realtime, Edge Functions)
- **Streaming SFU**: [LiveKit Cloud/OSS](https://livekit.io/)
- **Navigation**: [GoRouter](https://pub.dev/packages/go_router)
- **Local Storage**: [Hive](https://pub.dev/packages/hive_flutter)
- **Real-time Comms**: [Supabase Realtime](https://supabase.com/realtime) (Broadcast channels for chat & interactions)
- **Error Tracking**: [Sentry](https://sentry.io/)

---

## 📂 Project Architecture

The project follows a **Feature-First Domain-Driven Design (DDD)** approach for high maintainability:

```text
lib/
├── features/
│   ├── auth/             # Login, Google Sign-In, Session management
│   ├── home/             # Student dashboard & class joining
│   ├── session/          # Interactive question/response logic
│   └── stream/           # LiveKit integration, Chat, Hand Raising
├── core/
│   ├── constants/        # Design system tokens, API endpoints
│   ├── services/         # Shared singleton services (Supabase, Analytics)
│   └── theme/            # "Editorial Serenity" UI configuration
└── shared/               # Common widgets, models, and utilities
```

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK v3.10.7+
- A Supabase Project (with Edge Functions enabled)
- A LiveKit Cloud account (or self-hosted instance)

### Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/RahulMirji/Class-Twin-Mobile-App.git
   cd Class-Twin-Mobile-App
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Configure Environment**:
   Create a `.env` file or update your configuration with:
   - `SUPABASE_URL`
   - `SUPABASE_ANON_KEY`
   - `LIVEKIT_WS_URL`

4. **Run the App**:
   ```bash
   flutter run
   ```

---

## 📱 Developer Notes

> [!IMPORTANT]
> **LiveKit Tokens**: Students connect as *Subscribers* only. Room tokens are generated via Supabase Edge Functions (`/functions/v1/livekit-token`) to ensure secure access.

> [!TIP]
> **Performance**: Use `flutter build apk --release` to test streaming performance. Aggressive R8/ProGuard rules are recommended for production builds.

---

## 📄 License

Distributed under the MIT License. See `LICENSE` for more information.

---

*Built with ❤️ for the future of education.*

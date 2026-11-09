# API contract mapping

Source of truth: [GYMUP V1 - API 기명서](https://held-space-801.notion.site/74a03c3f306b8340af6b8173d381f661?v=93703c3f306b82e6b84d0895f7f570b7&source=copy_link).

The Notion table contains 25 endpoint rows. This implementation follows the user's explicit decision to use that table as the source of truth. All endpoints use `Authorization: Bearer <JWT>` with `USER` access. Fields are required unless the specification marks them optional; `beforeWorkoutId` is the only optional field listed here. Server errors retain the `{detail:{code,message}}` envelope for later UI mapping.

## Networking foundation scope

`APIEnvironment(baseURL:)`, `APIEnvironmentConfiguration`, and `APIServiceContainer` provide the networking foundation and centralize API client/service construction. Debug builds read `GYMUP_API_BASE_URL` from `Config/Info-Debug.plist`, explicitly set to `http://localhost:8000`. The generated Release Info.plist exposes the same key, supplied by the `GYMUP_API_BASE_URL` build setting (for example, an Xcode Release configuration or `xcodebuild ... GYMUP_API_BASE_URL=https://api.example.com`); there is no localhost fallback. `APIEnvironmentConfiguration` rejects a missing or invalid value, so container creation fails safely.

`BearerTokenProviding` is injectable into `APIServiceContainer`, but this repository has no production implementation. `DevelopmentBearerTokenProvider` is compiled only in Debug builds. The app therefore does not create API services or send API requests in Release until a production token provider is added and injected. The configured Release base URL alone does not enable requests.

| Method | Path | Success | Query | Request body | Headers | Response fields |
| --- | --- | ---: | --- | --- | --- | --- |
| `PUT` | `/api/v1/users/me/onboarding` | 200 | — | `experienceLevel`, `goalType`, `weeklyWorkoutTarget` | `Authorization` | `userId`, `profileCompleted`, `experienceLevel`, `goalType`, `weeklyWorkoutTarget` |
| `POST` | `/api/v1/goals` | 201 | — | `goalType`, `startDate`, `endDate`, `weeklyWorkoutTarget` | `Authorization` | `goalId`, `status`, `growth`, `weeklyGoal(weekStart,targetCount,completedCount)` |
| `GET` | `/api/v1/goals/active/progress` | 200 | — | — | `Authorization` | `goalId`, `growth`, `previousGrowth`, `stage`, `factors` (`JSONValue`), `updatedAt` |
| `PATCH` | `/api/v1/users/me/settings/rest-time` | 200 | — | `defaultRestSeconds` | `Authorization` | `defaultRestSeconds`, `updatedAt` |
| `PATCH` | `/api/v1/routines/{routineId}/exercises` | 200 | — | `add` (items: `exerciseId`, `sets`, `reps`, `weight`, `restSeconds`, `order`), `update` (items: `exerciseId`, `sets`, `reps`, `weight`, `restSeconds`), `removeExerciseIds` | `Authorization` | `routineId`, `exercises` (items: `exerciseId`, `sets`, `reps`, `weight`, `restSeconds`, `order`), `updatedAt` |
| `PUT` | `/api/v1/routines/{routineId}/exercises/order` | 200 | — | `exerciseIds` | `Authorization` | `routineId`, `orderedExercises` (items: `exerciseId`, `sets`, `reps`, `weight`, `restSeconds`, `order`), `updatedAt` |
| `PUT` | `/api/v1/routines/{routineId}/playlist` | 200 | — | `provider`, `playlistId`, `playlistName`, `externalUrl` | `Authorization` | `routineId`, `playlist(provider,playlistId,playlistName,externalUrl)`, `updatedAt` |
| `GET` | `/api/v1/photos` | 200 | `cursor`, `size`, `from`, `to`, `sort` | — | `Authorization` | `items(photoId,workoutId,capturedAt,thumbnailUrl)`, `nextCursor` |
| `GET` | `/api/v1/photos/{photoId}/download-url` | 200 | — | — | `Authorization` | `photoId`, `downloadUrl`, `expiresAt` |
| `POST` | `/api/v1/photos/{photoId}/stamps` | 202 | — | `layoutId`, `fields` (`routine`, `duration`, `sets`, `growth`, `xp`) | `Authorization` | `jobId`, `photoId`, `status` (`PROCESSING`) |
| `POST` | `/api/v1/photos/{photoId}/filters` | 202 | — | `preset`, `adjustments(contrast,shadow,sharpness,highlight,tone)` | `Authorization` | `jobId`, `photoId`, `status` (`PROCESSING`) |
| `POST` | `/api/v1/workouts/{workoutId}/photos` | 201 | — | `fileName`, `contentType`, `size` | `Authorization` | `photoId`, `uploadUrl`, `uploadHeaders` (`JSONValue`), `expiresAt` |
| `GET` | `/api/v1/statistics/exercises/{exerciseId}` | 200 | `metric`, `from`, `to`, `interval` | — | `Authorization` | `exerciseId`, `metric`, `points(date,value)`, `summary` (`JSONValue`) |
| `GET` | `/api/v1/workouts/{workoutId}` | 200 | — | — | `Authorization` | `workoutId`, `routine` (`JSONValue`), `duration`, `totalSets`, `volume`, `exercises(sets(reps,weight,pr))` |
| `GET` | `/api/v1/workouts` | 200 | `cursor`, `size`, `from`, `to`, `routineId` | — | `Authorization` | `items(workoutId,date,routineName,duration,totalSets,volume)`, `nextCursor` |
| `GET` | `/api/v1/workouts/{workoutId}/summary` | 200 | — | — | `Authorization` | `duration`, `totalSets`, `volume`, `prs` (`JSONValue`), `growthDelta` (`JSONValue`), `xp`, `levelUp` (`JSONValue`), `avatarGrowth` (`JSONValue`), `progressShotAvailable` |
| `POST` | `/api/v1/workouts/{workoutId}/complete` | 200 | — | `endedAt`, `expectedVersion` | `Authorization` | `workoutId`, `status` (`COMPLETED`), `duration`, `totalSets`, `volume`, `prs` (`JSONValue`), `xp`, `growthDelta` (`JSONValue`) |
| `POST` | `/api/v1/tools/plate-calculator` | 200 | — | `targetWeight`, `barWeight`, `availablePlates` (items: `JSONValue`) | `Authorization` | `achievable`, `eachSide(weight,count)`, `actualWeight`, `remainder` |
| `GET` | `/api/v1/workouts/{workoutId}/next-set` | 200 | — | — | `Authorization` | `exerciseId`, `exerciseName`, `setIndex`, `weight`, `reps`, `restEndsAt` |
| `GET` | `/api/v1/workouts/{workoutId}/rests/current` | 200 | — | — | `Authorization` | `restId`, `status`, `startedAt`, `endsAt`, `remainingSeconds`, `notificationAt` |
| `POST` | `/api/v1/workouts/{workoutId}/rests/current/skip` | 200 | — | — | `Authorization` | `restId`, `status` (`SKIPPED`), `nextSet` (`JSONValue`) |
| `PATCH` | `/api/v1/workouts/{workoutId}/rests/current/extend` | 200 | — | `seconds` (15) | `Authorization` | `restId`, `endsAt`, `remainingSeconds` |
| `POST` | `/api/v1/workouts/{workoutId}/rests` | 201 | — | `setId`, `durationSeconds` | `Authorization` | `restId`, `startedAt`, `endsAt`, `durationSeconds`, `nextSet` (`JSONValue`) |
| `GET` | `/api/v1/exercises/{exerciseId}/first-time-status` | 200 | — | — | `Authorization` | `exerciseId`, `isFirstTime`, `guideAvailable` |
| `GET` | `/api/v1/exercises/{exerciseId}/guide` | 200 | — | — | `Authorization` | `exerciseId`, `mediaUrl`, `targetMuscles`, `keyPoints`, `commonMistakes` |
| `PATCH` | `/api/v1/workouts/{workoutId}/current-exercise` | 200 | — | `completedExerciseId` | `Authorization` | `workoutId`, `currentExercise` (`JSONValue`), `nextExercise` (`JSONValue`), `status` |
| `GET` | `/api/v1/exercises/{exerciseId}/previous-record` | 200 | `beforeWorkoutId` (optional) | — | `Authorization` | `exerciseId`, `hasPreviousRecord`, `weight`, `reps`, `setIndex`, `performedAt` |
| `POST` | `/api/v1/workouts/{workoutId}/sets` | 201 | — | `exerciseId`, `setIndex`, `weight`, `reps`, `completedAt` | `Authorization`; `Idempotency-Key` (recommended) | `setId`, `workoutId`, `exerciseId`, `setIndex`, `pr`, `nextAction` (`JSONValue`), `rest` (`JSONValue`) |
| `POST` | `/api/v1/workouts` | 201 | — | `routineId`, `startedAt`, `timezone` | `Authorization` | `workoutId`, `status` (`IN_PROGRESS`), `routineSnapshot` (`JSONValue`), `currentExercise` (`JSONValue`), `startedAt` |

For the workout photo route, the client requests upload metadata after the user saves the rendered workout photo to Photos, then sends the image bytes with a `PUT` to the returned storage URL using only the server-provided `uploadHeaders`. The signed storage request does not use the app's Bearer token. Failed storage uploads can retry the same URL while it remains valid; retrying does not create another metadata record. The app currently has no production bearer token provider, so API services remain unavailable in Release builds until one is added and injected.

Routine editing sends exercise additions, field updates, removals, and an absolute exercise order through the two documented routes above. Exercise writes include only fields accepted by the backend. The editor's routine title remains locally editable; neither route accepts a name update, so the title is not sent to the server and the existing server routine name remains unchanged.

An exercise `PATCH` can have an ambiguous outcome if the server applies it but the response is lost. The iOS editor keeps the exact request for retry and uses the server's returned exercise state before attempting a separate order `PUT`. Safe retry of an ambiguous `add` depends on the approved paired backend hardening: repeated items must be idempotent by `exerciseId`, updating their fields without changing their current order. The absolute order `PUT` remains authoritative. This iOS change does not add an idempotency header or alter the request shape.

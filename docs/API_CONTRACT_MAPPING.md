# API contract mapping

Source of truth: [GYMUP V1 - API 기명서](https://held-space-801.notion.site/74a03c3f306b8340af6b8173d381f661?v=93703c3f306b82e6b84d0895f7f570b7&source=copy_link).

The Notion table contains 25 endpoint rows. This implementation follows the user's explicit decision to use that table as the source of truth. All endpoints use `Authorization: Bearer <JWT>` with `USER` access. Fields are required unless the specification marks them optional; `beforeWorkoutId` is the only optional field listed here. Server errors retain the `{detail:{code,message}}` envelope for later UI mapping.

## Networking foundation scope

`APIEnvironment(baseURL:)`, the API client, and endpoint services provide the networking foundation, but app composition does not create or use them yet; no real server requests are connected to app flows. Supplying the base URL from app configuration and wiring services into the app are follow-up work.

| Method | Path | Success | Query | Request body | Headers | Response fields |
| --- | --- | ---: | --- | --- | --- | --- |
| `PUT` | `/api/v1/users/me/onboarding` | 200 | — | `experienceLevel`, `goalType`, `weeklyWorkoutTarget` | `Authorization` | `userId`, `profileCompleted`, `experienceLevel`, `goalType`, `weeklyWorkoutTarget` |
| `PATCH` | `/api/v1/users/me/settings/rest-time` | 200 | — | `defaultRestSeconds` | `Authorization` | `defaultRestSeconds`, `updatedAt` |
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

For the workout photo route, this contract describes the documented metadata request and upload URL response. The user decided the binary `PUT` to the returned storage URL is a separate follow-up task.

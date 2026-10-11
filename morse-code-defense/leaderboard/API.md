# Leaderboard server API

What the game expects from the leaderboard server. The game side is `leaderboard/leaderboard_api.gd` (the `Leaderboard` autoload).

## Connecting the game

Set `BASE_URL` at the top of `leaderboard_api.gd` to the server's address, with no trailing slash:

```gdscript
const BASE_URL := "https://example.com/api"
```

While `BASE_URL` is empty, the game keeps scores in a local file (`user://leaderboard.json`) so the screens work before the server exists.

All requests and replies are JSON (`Content-Type: application/json`). The game gives up after 10 seconds.

## Names and scores

- **name**: exactly 3 characters, each a letter, number or symbol: printable ASCII from `!` (33) to `~` (126). No spaces. Case is kept as typed (`aB3` is allowed).
- **score**: a whole number, 0 or more. Higher is better.

The game already checks both before sending, but the server should check them too and reject anything else.

## `GET /scores?limit=10`

The top scores, highest first. `limit` is how many to return (the game asks for 10).

**200 OK**
```json
{
  "scores": [
    { "name": "ABC", "score": 1200 },
    { "name": "x_7", "score": 950 }
  ]
}
```

Extra fields per entry (an id, a date) are fine; the game ignores them. An empty board is `{ "scores": [] }`.

## `POST /scores`

Save one score at the end of a run.

**Request**
```json
{ "name": "ABC", "score": 1200 }
```

**201 Created** (200 is also accepted)
```json
{ "rank": 4 }
```

`rank` is the new score's position on the whole board, starting at 1 for the highest. The game shows it to the player ("You placed #4"). If it's missing, the game just doesn't show a rank.

**400 Bad Request** for an invalid name or score:
```json
{ "error": "Names must be exactly 3 characters." }
```

## Errors

For any error status (4xx or 5xx), send `{ "error": "..." }` with a short message. The game shows that message to the player as-is, so keep it readable. If there's no `error` field, the game shows a generic message with the status code.

## Quick check with curl

```bash
curl "$BASE_URL/scores?limit=10"
curl -X POST "$BASE_URL/scores" -H "Content-Type: application/json" -d '{"name":"ABC","score":1200}'
```

## The website

The project website shows the leaderboard with `website/leaderboard-widget.html`, which calls `GET /scores` from the visitor's browser. For that to work the server needs two more things:

- **HTTPS.** The website is served over `https://`, and browsers block a secure page from calling a plain `http://` server.
- **CORS on `GET /scores`.** Browsers only let another site read the reply if the server says it's allowed. Add this header to `GET /scores` replies (scores are public, so allowing any site is fine):
  ```
  Access-Control-Allow-Origin: *
  ```
  `POST /scores` doesn't need it while the game is a desktop download. If the game is also published as a browser (Web) build, `POST /scores` needs the same header, and the server must also answer the browser's `OPTIONS /scores` check with `Access-Control-Allow-Methods: GET, POST` and `Access-Control-Allow-Headers: Content-Type`.
